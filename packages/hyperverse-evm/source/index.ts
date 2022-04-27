export * from '@decentology/web3modal';
import { useEvm} from './useEVM';
import {Provider, ProviderProps, lightTheme, darkTheme} from './Provider'
import { Blockchain, makeHyperverseBlockchain } from '@decentology/hyperverse';
import { getProvider } from './evmLibraryBase';
export { EvmLibraryBase } from './evmLibraryBase';

export const Ethereum = makeHyperverseBlockchain({
	name: Blockchain.Ethereum,
		// @ts-ignore
	Provider: Provider,
});

export const Localhost = makeHyperverseBlockchain({
	name: Blockchain.Localhost,
	// @ts-ignore
	Provider: Provider,
});

export type {ProviderProps}
export { Provider, useEvm, getProvider, lightTheme, darkTheme};
