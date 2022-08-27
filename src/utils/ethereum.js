import { ethers } from "ethers";
import abi from "./abi.json";

export const contract = () => {
	const { ethereum } = window;
	const provider = new ethers.providers.Web3Provider(window.ethereum);
	if (ethereum) {
		const signer = provider.getSigner();
		const contractReader = new ethers.Contract(
			"0xa513e6e4b8f2a923d98304ec87f64353c4d5c853",
			abi,
			signer
		);
		return contractReader;
	}
};
