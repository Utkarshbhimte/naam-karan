//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './BuildENSMain.sol';
import './NFTSubdomain.sol';

contract SubdomainFactory is Ownable {
	bytes32 constant ensHash = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

	enum ContractType {
		Merkle,
		NFT
	}

	struct NFTSubdomainContractsInfo {
		NFTSubdomain subdomain;
		address creator;
	}

	struct MerkleSubdomainContractsInfo {
		MerkleSubdomain subdomain;
		address creator;
	}

	MerkleSubdomainContractsInfo[] public merkleContracts;
	NFTSubdomainContractsInfo[] public nftContracts;

	constructor() {}

	function createNFTContract(address nftContractAddress, string memory domainName) public {
		bytes32 domainHash = getDomainHash(domainName);
		NFTSubdomain newBuild = new NFTSubdomain(nftContractAddress, domainName, domainHash);
		nftContracts.push(NFTSubdomainContractsInfo({ subdomain: newBuild, creator: msg.sender }));
	}

	function createMerkleContract(bytes32 merkleHash, string memory domainName) public {
		bytes32 domainHash = getDomainHash(domainName);
		MerkleSubdomain newBuild = new MerkleSubdomain(merkleHash, domainName, domainHash);
		merkleContracts.push(MerkleSubdomainContractsInfo({ subdomain: newBuild, creator: msg.sender }));
	}

	function updateMerkleHash(uint256 _id, bytes32 _hash) public onlyCreator(ContractType.Merkle, _id) {
		// @abhishek how can we verify that the hash is right? And only then update the merkle hash
		merkleContracts[_id].subdomain.updateMerkleHash(_hash);
	}

	/**
		Modifies
	 */
	modifier onlyCreator(ContractType _type, uint256 _id) {
		if (_type == ContractType.Merkle) {
			require(msg.sender == merkleContracts[_id].creator, 'Not the creator of this merkle contract');
			_;
		}

		if (_type == ContractType.NFT) {
			require(msg.sender == nftContracts[_id].creator, 'Not the creator of this NFT contract');
			_;
		}

		require(false, 'Somethings not right');
		_;
	}

	/**
		Utils method
	 */

	function getDomainHash(string memory domain) public pure returns (bytes32) {
		bytes32 label = keccak256(bytes(domain));
		bytes32 domainHash = keccak256(abi.encodePacked(ensHash, label));
		return domainHash;
	}
}
