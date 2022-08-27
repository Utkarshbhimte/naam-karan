// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleTest {
    bytes32 public root = 0xd69c2dd8b6f0e3b0923279376857cda7a63148f5789858d943bed113476361d5;

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}