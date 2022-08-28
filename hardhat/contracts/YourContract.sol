pragma solidity >=0.8.4;
import { INameWrapper, PublicResolver } from '@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol';
import '@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol';
import '@ensdomains/ens-contracts/contracts/registry/FIFSRegistrar.sol';
import '@ensdomains/ens-contracts/contracts/ethregistrar/ETHRegistrarController.sol';
import { NameResolver, ReverseRegistrar } from '@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol';

// Construct a set of test ENS contracts.
contract ENSDeployer {
	bytes32 public constant TLD_LABEL = keccak256('eth');
	bytes32 public constant RESOLVER_LABEL = keccak256('resolver');
	bytes32 public constant REVERSE_REGISTRAR_LABEL = keccak256('reverse');
	bytes32 public constant ADDR_LABEL = keccak256('addr');

	ENSRegistry public ens;
	FIFSRegistrar public fifsRegistrar;
	ReverseRegistrar public reverseRegistrar;
	PublicResolver public publicResolver;

	function namehash(bytes32 node, bytes32 label) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(node, label));
	}

	constructor() public {
		ens = new ENSRegistry();

		// Set up the resolver
		bytes32 resolverNode = namehash(bytes32(0), RESOLVER_LABEL);

		ens.setSubnodeOwner(bytes32(0), RESOLVER_LABEL, address(this));
		ens.setResolver(resolverNode, address(publicResolver));
		publicResolver.setAddr(resolverNode, address(publicResolver));

		// Create a FIFS registrar for the TLD
		fifsRegistrar = new FIFSRegistrar(ens, namehash(bytes32(0), TLD_LABEL));

		ens.setSubnodeOwner(bytes32(0), TLD_LABEL, address(fifsRegistrar));

		// Construct a new reverse registrar and point it at the public resolver
		reverseRegistrar = new ReverseRegistrar(ens);

		/* 
			ETHRegistrarController requires six arguments which I could not figure out what they are or are they even required here.
			https://github.com/ensdomains/ens-contracts/blob/7b303495171edf173e84089732c82b53a955b9cf/deploy/ethregistrar/03_deploy_eth_registrar_controller.ts#L15

			Those arguments would require more contracts to be included here and hence I ma pausing before going down the rabbit hole.		
		 */
		registrarController = new ETHRegistrarController(ens);

		// ENS _ens, INameWrapper wrapperAddress, address _trustedETHController, address _trustedReverseRegistrar
		publicResolver = new PublicResolver(ens, INameWrapper(address(0), registrarController, reverseRegistrar));

		// Set up the reverse registrar
		ens.setSubnodeOwner(bytes32(0), REVERSE_REGISTRAR_LABEL, address(this));
		ens.setSubnodeOwner(namehash(bytes32(0), REVERSE_REGISTRAR_LABEL), ADDR_LABEL, address(reverseRegistrar));
	}
}
