pragma solidity ^0.8.4;

//eip155:1/erc721:0x4b10701bfd7bfedc47d50562b76b436fbb5bdb3b/590

//SPDX-License-Identifier: MIT

// Forked from: lilnouns.eth subdomain registrar contract
// https://etherscan.io/address/0x27c4f6ff6935537c9cc05f4eb40e666d8f328918#code

//Twitter: @hodl_pcc

pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IReverseResolver {
	function setName(string memory name) external;
}

contract ENSSubdomain is Ownable {
	using Strings for uint256;

	bytes32 public merkleRootHash;
	address constant REVERSE_RESOLVER_ADDRESS =
		0x084b1c3C81545d370f3634392De611CaaBFf8148;

	IReverseResolver public constant ReverseResolver =
		IReverseResolver(REVERSE_RESOLVER_ADDRESS);
	ENS private constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

	// use merkle root instead of nft
	// IERC721 constant public nft = IERC721(0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B);

	// lilnouns domain ??
	bytes32 public constant domainHash =
		0xad1a6da3cc06e58ea001eca64ff32d6871edf6108b38ffb3e0de3bf9472302cc;

	mapping(bytes32 => mapping(string => string)) public texts;

	string public constant domainLabel = "rohit";

	mapping(bytes32 => address) public hashToAddressMap;
	mapping(address => bytes32) public addressToHashmap;
	mapping(bytes32 => string) public hashToDomainMap;

	event TextChanged(
		bytes32 indexed node,
		string indexed indexedKey,
		string key
	);
	event RegisterSubdomain(address indexed registrar, string indexed label);

	event AddrChanged(bytes32 indexed node, address a);

	constructor() {}

	//<interface-functions>
	function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
		return
			interfaceID == 0x3b3b57de || //addr
			interfaceID == 0x59d1d43c || //text
			interfaceID == 0x691f3431 || //name
			interfaceID == 0x01ffc9a7; //supportsInterface << [inception]
	}

	function text(bytes32 node, string calldata key)
		external
		view
		returns (string memory)
	{
		address currentAddress = hashToAddressMap[node];
		require(addressToHashmap[currentAddress] != 0x0, "Invalid address");
		return texts[node][key];
	}

	// // @rohit need to check this out, what can we return from this?
	// function addr(bytes32 nodeID) public view returns (address) {
	// 	address currentAddress = hashToAddressMap[nodeID];
	// 	require(addressToHashmap[currentAddress] != 0x0, "Invalid address");
	// 	return addressToHashmap[currentAddress];
	// }

	function name(bytes32 node) public view returns (string memory) {
		return
			(bytes(hashToDomainMap[node]).length == 0)
				? ""
				: string(
					abi.encodePacked(
						hashToDomainMap[node],
						".",
						domainLabel,
						".eth"
					)
				);
	}

	//</interface-functions>

	//--------------------------------------------------------------------------------------------//

	//<read-functions>
	function getDomainHash(string calldata label)
		public
		view
		returns (bytes32)
	{
		bytes32 encodedLabel = keccak256(abi.encodePacked(label));
		bytes32 domainLabelHash = keccak256(
			abi.encodePacked(domainHash, encodedLabel)
		);
		return
			hashToAddressMap[domainLabelHash] != address(0)
				? domainLabelHash
				: bytes32(0x0);
	}

	function getDomainOwner(string calldata label)
		public
		view
		returns (address)
	{
		bytes32 encodedLabel = keccak256(abi.encodePacked(label));
		bytes32 domainLabelHash = keccak256(
			abi.encodePacked(domainHash, encodedLabel)
		);
		return hashToAddressMap[domainLabelHash];
	}

	function getAddressDomain(address addr)
		private
		view
		returns (string memory uri)
	{
		require(
			addressToHashmap[addr] != 0x0,
			"Address has not bought a sub-domain yet"
		);
		uri = string(
			abi.encodePacked(
				hashToDomainMap[addressToHashmap[addr]],
				".",
				domainLabel,
				".eth"
			)
		);
	}

	function getAddressesDomains(address[] memory addresses)
		external
		view
		returns (string[] memory)
	{
		string[] memory uris = new string[](addresses.length);
		for (uint256 i; i < addresses.length; i++) {
			uris[i] = getAddressDomain(addresses[i]);
		}
		return uris;
	}

	//</read-functions>

	//--------------------------------------------------------------------------------------------//

	//<authorised-functions>
	function claimSubdomain(string calldata label, bytes32[] calldata proof)
		public
		isAuthorised(proof)
	{
		require(addressToHashmap[msg.sender] == 0x0, "Already owned");

		bytes32 encodedLabel = keccak256(abi.encodePacked(label));
		bytes32 domainLabelHash = keccak256(
			abi.encodePacked(domainHash, encodedLabel)
		);

		//ens.recordExists seems to not be reliable (tested removing records through ENS control panel and this still returns true)
		require(
			!ens.recordExists(domainLabelHash) || msg.sender == owner(),
			"sub-domain already exists"
		);

		ens.setSubnodeRecord(
			domainHash,
			encodedLabel,
			msg.sender,
			address(this),
			0
		);

		hashToAddressMap[domainLabelHash] = msg.sender;
		addressToHashmap[msg.sender] = domainLabelHash;
		hashToDomainMap[domainLabelHash] = label;

		emit RegisterSubdomain(msg.sender, label);
		emit AddrChanged(domainLabelHash, msg.sender);
	}

	function setText(
		bytes32 node,
		string calldata key,
		string calldata value // isAuthorised(hashToAddressMap[node])
	) external {
		require(
			addressToHashmap[hashToAddressMap[node]] != 0x0,
			"That node doesn't have a domain owned yet in this contract!"
		);

		texts[node][key] = value;
		emit TextChanged(node, key, value);
	}

	function setContractName(string calldata _name) external onlyOwner {
		ReverseResolver.setName(_name);
	}

	function resetHash(bytes32[] calldata proof) public isAuthorised(proof) {
		bytes32 domainLabelHash = addressToHashmap[msg.sender];
		require(domainLabelHash != 0x0, "Sub-domain does not exist");

		//reset domain mappings
		delete hashToDomainMap[domainLabelHash];
		delete hashToAddressMap[domainLabelHash];
		delete addressToHashmap[msg.sender];

		// TODO Need to set back the owner of the NFT to this contract.

		emit AddrChanged(domainLabelHash, address(0));
	}

	//</authorised-functions>

	//--------------------------------------------------------------------------------------------//

	// <owner-functions>

	function renounceOwnership() public override onlyOwner {
		require(false, "ENS is responsibility. You cannot renounce ownership.");
		super.renounceOwnership();
	}

	//</owner-functions>

	modifier isAuthorised(bytes32[] calldata proof) {
		require(
			owner() == msg.sender ||
				isValid(proof, keccak256(abi.encodePacked(msg.sender))),
			"Not authorised"
		);
		_;
	}

	function updateRoot(bytes32 _root) public onlyOwner {
		merkleRootHash = _root;
	}

	function isValid(bytes32[] memory proof, bytes32 leaf)
		public
		view
		returns (bool)
	{
		return MerkleProof.verify(proof, merkleRootHash, leaf);
	}
}
