import { ethers } from 'ethers'
import abi from './abi.json'

export const contract = () => {
	const { ethereum } = window
	const provider = new ethers.providers.Web3Provider(window.ethereum)
	if (ethereum) {
		const signer = provider.getSigner()
		const contractReader = new ethers.Contract('0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0', abi, signer)
		return contractReader
	}
}
