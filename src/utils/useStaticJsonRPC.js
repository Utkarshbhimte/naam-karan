import { useCallback, useEffect, useState } from 'react'
import { ethers } from 'ethers'

const createProvider = async url => {
	const p = new ethers.providers.StaticJsonRpcProvider(url)

	await p.ready

	return p
}

export const localRpcUrl = process.env.REACT_APP_CODESPACES
	? `https://${window.location.hostname.replace('3000', '8545')}`
	: 'http://' + (global.window ? window.location.hostname : 'localhost') + ':8545'

export default function useStaticJsonRPC() {
	const urlArray = [localRpcUrl]

	const [provider, setProvider] = useState(null)

	const handleProviders = useCallback(async () => {
		try {
			const p = await Promise.race(urlArray.map(createProvider))
			const _p = await p

			setProvider(_p)
		} catch (error) {
			// todo: show notification error about provider issues
			console.log(error)
		}
	}, [])

	useEffect(() => {
		handleProviders()
		// eslint-disable-next-line
	}, [])

	return provider
}
