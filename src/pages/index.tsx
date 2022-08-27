import { ethers } from "ethers";
import React, { useEffect, useState } from "react";
import Transactor from "../utils/funds";
import useStaticJsonRPC from "../utils/useStaticJsonRPC";
import { contract } from "../utils/ethereum";
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";

export const connectWallet = async () => {
	try {
		if (!window) {
			throw new Error("No window object");
		}

		const { ethereum } = window;

		if (!ethereum) {
			alert("Get MetaMask!");
			return;
		}

		/*
		 * Fancy method to request access to account.
		 */

		// let chainId = await ethereum.request({ method: "eth_chainId" });
		// console.log(chainId);
		// console.log("Connected to chain " + chainId);

		// // String, hex code of the chainId of the Rinkebey test network
		// const rinkebyChainId = "0x4";
		// if (chainId !== rinkebyChainId) {
		// 	alert("You are not connected to the Rinkeby Test Network!");
		// 	throw new Error(
		// 		"You are not connected to the Rinkeby Test Network!"
		// 	);
		// }

		const accounts = await ethereum.request({
			method: "eth_requestAccounts",
		});

		/*
		 * Boom! This should print out public address once we authorize Metamask.
		 */
		console.log({ accounts });
		console.log("Connected", accounts[0]);

		return accounts[0];
	} catch (error) {
		console.log(error);
	}
};

const Read = () => {
	const localProvider = useStaticJsonRPC();

	const [address, setAddress] = useState("");

	const addresses = [
		"0x631046bc261e0b2e3db480b87d2b7033d9720c90",
		"0xad6561e9e306c923512b4ea7af902994bebd99b8",
		"0x127309CeBaA72cb97AD6623379a0cBf4fa8F5a94",
		"0x032180b003b74BF72B983544543Ce86799d9a634",
	];

	const generateMerkleTree = () => {
		const hashedAddresses = addresses.map((address) => keccak256(address));
		const merkleTree = new MerkleTree(hashedAddresses, keccak256, {
			sortPairs: true,
		});
		const rootHash = "0x" + merkleTree.getRoot().toString("hex");

		return { merkleTree, rootHash };
	};

	const addressMerkleTree = () => {
		const { merkleTree, rootHash } = generateMerkleTree();
		const hex = merkleTree.getHexRoot();
		console.log("-- Generated Merkle Tree --");
		console.log({ hex });
	};

	const verifyWeb = () => {
		const { merkleTree, rootHash } = generateMerkleTree();
		let hashedAddress = keccak256(address);
		console.log({ hashedAddress: hashedAddress.toString("hex") });
		let proof = merkleTree.getHexProof(hashedAddress);
		console.log(proof);

		// Check proof
		let v = merkleTree.verify(proof, hashedAddress, rootHash);
		console.log("-- Verified in web --");
		console.log(v); // returns true
	};

	const verifySmartContract = async () => {
		const { merkleTree, rootHash } = generateMerkleTree();
		console.log({ address });
		let hashedAddress = keccak256(address);

		const stringhash = `0x${hashedAddress.toString("hex")}`;

		let proof = merkleTree.getHexProof(hashedAddress);
		console.log(proof);

		const tx = await contract().isValid(proof, stringhash);
		console.log({ tx });
		// await tx.wait();
	};

	const setRoot = async () => {
		const { rootHash } = generateMerkleTree();

		// const tx = await contract().setContractRoot(rootHash);
		// await tx.wait();
		// console.log({ tx });
		const root = await contract().root();
		console.log({ root });
	};

	const faucetTx = Transactor(localProvider);

	return (
		<>
			<button
				className=" bg-blue-400 rounded-md px-4 py-1"
				onClick={() => {
					console.log("hello");
					faucetTx({
						to: "0xF2AA5E0835A6105B4917076ea178520a99EEF903",
						value: ethers.utils.parseEther("1"),
					});
				}}
			>
				Funds plis
			</button>
			<div className="flex space-y-4 flex-col m-4">
				<div>
					<button
						className=" bg-blue-400 rounded-md px-4 py-1"
						onClick={addressMerkleTree}
					>
						Generate Merkle Tree
					</button>
				</div>
				<div>
					<input
						className=" bg-slate-200 px-2 py-1 rounded-md text-black"
						value={address}
						onChange={(e) => setAddress(e.target.value)}
						placeholder="Address to verify"
					/>
				</div>
				<div className="flex space-x-4">
					<button
						className=" bg-blue-400 rounded-md px-4 py-1"
						onClick={verifyWeb}
					>
						Verify from Web ( Check in console )
					</button>
					<button
						className=" bg-blue-400 rounded-md px-4 py-1"
						onClick={setRoot}
					>
						Set root
					</button>
					<button
						className=" bg-blue-400 rounded-md px-4 py-1"
						onClick={verifySmartContract}
					>
						Verify from Smart Contract ( Check in console )
					</button>
				</div>
			</div>

			<button onClick={connectWallet}>Connect</button>
		</>
	);
};

export default Read;
