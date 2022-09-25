//eip155:1/erc721:0x4b10701bfd7bfedc47d50562b76b436fbb5bdb3b/590

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@ensdomains/ens-contracts/contracts/registry/ENS.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './IReverseResolver.sol';

contract NFTSubdomain is Ownable {
	using Strings for uint256;

	bytes32 public domainHash;
	string public domainLabel;
	IERC721 public nft;

	address constant REVERSE_RESOLVER_ADDRESS = 0x084b1c3C81545d370f3634392De611CaaBFf8148;

	IReverseResolver public constant ReverseResolver = IReverseResolver(REVERSE_RESOLVER_ADDRESS);
	ENS private constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

	mapping(bytes32 => address) public hashToAddressMap;
	mapping(bytes32 => string) public hashToDomainMap;
	mapping(address => bytes32) public addressToHashmap;
	mapping(uint => address) public tokenIdToAddressMap;
	mapping(bytes32 => mapping(string => string)) public texts;

	event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
	event RegisterSubdomain(address indexed registrar, string indexed label);

	event AddrChanged(bytes32 indexed node, address a);
	event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);

	constructor(
		address _nftContractAddress,
		string memory _domainLabel,
		bytes32 _domainHash
	) {
		nft = IERC721(_nftContractAddress);
		domainLabel = _domainLabel;
		domainHash = _domainHash;
	}

	//<interface-functions>
	function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
		return
			interfaceID == 0x3b3b57de || //addr
			interfaceID == 0x59d1d43c || //text
			interfaceID == 0x691f3431 || //name
			interfaceID == 0x01ffc9a7; //supportsInterface << [inception]
	}

	function getDomainForTokenId(uint _tokenId) public view returns (string memory) {
		require(tokenIdToAddressMap[_tokenId] != address(0), "Domain not found with that tokenId");
		address _address = tokenIdToAddressMap[_tokenId];
		bytes32 _hash = addressToHashmap[_address];
		return hashToDomainMap[_hash];
	}

	function text(bytes32 node, string calldata key) external view returns (string memory) {
		address currentAddress = hashToAddressMap[node];
		require(addressToHashmap[currentAddress] != 0x0, 'Invalid address');
		return texts[node][key];
	}

	function addr(bytes32 nodeID) public view returns (address) {
		address currentAddress = hashToAddressMap[nodeID];
		// update the check for null address
		require(addressToHashmap[currentAddress] != 0x0, 'Invalid address');
		return hashToAddressMap[nodeID];
	}

	function name(bytes32 node) public view returns (string memory) {
		return
			(bytes(hashToDomainMap[node]).length == 0)
				? ''
				: string(abi.encodePacked(hashToDomainMap[node], '.', domainLabel, '.eth'));
	}

	//</interface-functions>

	//--------------------------------------------------------------------------------------------//

	//<read-functions>
	function domainMap(string calldata label) public view returns (bytes32) {
		bytes32 encoded_label = keccak256(abi.encodePacked(label));
		bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

		return hashToAddressMap[big_hash] != address(0) ? big_hash : bytes32(0x0);
	}

	//</read-functions>

	//--------------------------------------------------------------------------------------------//

	//<authorised-functions>
	function claimSubdomain(string calldata label, uint _tokenId) public isNFTOwner(_tokenId) {
		_claimSubdomain(label, _tokenId);
	}

	function reclaimSubdomain(string calldata label, uint _tokenId) public isNFTOwner(_tokenId) {

		// Checking with msg.sender since we are already checking if the sender is the owner of the NFT
		require(tokenIdToAddressMap[_tokenId] != msg.sender, "Can't reclaim a domain after claiming it!");

		// Resetting the older claimed subdomain
		_resetHash(_tokenId);

		// Claiming the new sub domain
		_claimSubdomain(label, _tokenId);
	}

	function _claimSubdomain(string calldata label, uint _tokenId) private {
		require(tokenIdToAddressMap[_tokenId] == address(0), 'Address already claimed subdomain');

		bytes32 encoded_label = keccak256(abi.encodePacked(label));
		bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

		//ens.recordExists seems to not be reliable (tested removing records through ENS control panel and this still returns true)

		require(!ens.recordExists(big_hash), 'sub-domain already exists');

		ens.setSubnodeRecord(domainHash, encoded_label, msg.sender, address(this), 0);

		hashToAddressMap[big_hash] = msg.sender;
		addressToHashmap[msg.sender] = big_hash;
		hashToDomainMap[big_hash] = label;
		tokenIdToAddressMap[_tokenId] = msg.sender;

		emit RegisterSubdomain(msg.sender, label);
		emit AddrChanged(big_hash, msg.sender);

	}

	function setText(
		bytes32 node,
		string calldata key,
		string calldata value,
		uint _tokenId
	) external isAuthorised(_tokenId) {
		address currentAddress = hashToAddressMap[node];

		require(currentAddress == msg.sender, "Can't change someone else subdomain text");
		require(addressToHashmap[currentAddress] != 0x0, 'Invalid address');

		texts[node][key] = value;
		emit TextChanged(node, key, key);
	}

	// @abhishek not sure what this does, but anyone can do this. Irrespective of the user is authorised or not
	function setContractName(string calldata _name) external {
		ReverseResolver.setName(_name);
	}

	function resetHash(uint _tokenId) public isAuthorised(_tokenId) {
		_resetHash(_tokenId);
	}

	function _resetHash(uint _tokenId) private {
		address _address = tokenIdToAddressMap[_tokenId];
		bytes32 currDomainHash = addressToHashmap[_address];
		require(ens.recordExists(currDomainHash), 'Sub-domain does not exist');

		//reset domain mappings
		delete hashToDomainMap[currDomainHash];
		delete hashToAddressMap[currDomainHash];
		delete addressToHashmap[msg.sender];
		delete tokenIdToAddressMap[_tokenId];

		emit AddrChanged(currDomainHash, address(0));
	}

	

	//</authorised-functions>

	//--------------------------------------------------------------------------------------------//

	// <owner-functions>

	modifier isAuthorised(uint _tokenId) {
		require(nft.ownerOf(_tokenId) == msg.sender, 'Unauthorised user');
		require(nft.ownerOf(_tokenId) == tokenIdToAddressMap[_tokenId], 'You need to claim the sub-domain first!');
		_;
	}

	modifier isNFTOwner(uint _tokenId) {
		require(nft.ownerOf(_tokenId) == msg.sender, 'Unauthorised user');
		_;
	}
	

	// </owner-functions>
}
