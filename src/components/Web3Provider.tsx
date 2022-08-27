import { ConnectKitProvider } from 'connectkit'
import { useTheme } from 'next-themes'
import { createClient, WagmiConfig } from 'wagmi'
import useStaticJsonRPC from '../utils/useStaticJsonRPC'

const Web3Provider = ({ children }) => {
	const { resolvedTheme } = useTheme()

	const localProvider = useStaticJsonRPC()

	const client = createClient({
		autoConnect: true,
		provider: localProvider,
	})
	return (
		<WagmiConfig client={client}>
			<ConnectKitProvider mode={resolvedTheme as 'light' | 'dark'}>{children}</ConnectKitProvider>
		</WagmiConfig>
	)
}

export default Web3Provider
