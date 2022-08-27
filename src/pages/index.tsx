import { ethers } from 'ethers'
import React, { useEffect } from 'react'
import Transactor from '../utils/funds'
import useStaticJsonRPC from '../utils/useStaticJsonRPC'
import { contract } from '../utils/ethereum'

export const connectWallet = async () => {
	try {
		if (!window) {
			throw new Error('No window object')
		}

		const { ethereum } = window

		if (!ethereum) {
			alert('Get MetaMask!')
			return
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
			method: 'eth_requestAccounts',
		})

		/*
		 * Boom! This should print out public address once we authorize Metamask.
		 */
		console.log({ accounts })
		console.log('Connected', accounts[0])

		return accounts[0]
	} catch (error) {
		console.log(error)
	}
}

const localRpcUrl = process.env.REACT_APP_CODESPACES
	? `https://${window.location.hostname.replace('3000', '8545')}`
	: 'http://' + (global.window ? window.location.hostname : 'localhost') + ':8545'

const Read = () => {
	const localProvider = useStaticJsonRPC()

	console.log({ localProvider })

	const readState = async () => {
		console.log('reading state')
		const reader = await contract().purpose()
		console.log(reader)
	}

	const writeState = async () => {
		const random = Math.random().toString()
		const reader = await contract().setPurpose(random)
		await reader.wait()

		await readState()
	}

	useEffect(() => {
		readState()
	}, [])

	const faucetTx = Transactor(localProvider)

	return (
		<>
			<div onClick={writeState}>Read</div>
			<button
				onClick={() => {
					console.log('hello')
					faucetTx({
						to: '0xF2AA5E0835A6105B4917076ea178520a99EEF903',
						value: ethers.utils.parseEther('1'),
					})
				}}
			>
				Funds plis
			</button>
			<button onClick={connectWallet}>Connect</button>
		</>
	)
}

export default Read
