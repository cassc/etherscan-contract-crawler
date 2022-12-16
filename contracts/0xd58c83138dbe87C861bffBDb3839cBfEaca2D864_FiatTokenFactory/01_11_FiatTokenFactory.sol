pragma solidity >0.5.0;

import "../node_modules/@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol";
import "../node_modules/@openzeppelin/upgrades/contracts/ownership/Ownable.sol";


/**
 * @author Simon Dosch
 * @title FiatTokenFactory
 * @dev Updateable contract factory for deploying Proxies
 */
contract FiatTokenFactory is ProxyFactory, OpenZeppelinUpgradesOwnable {
	/**
	 * @dev address of the master contract
	 */
	address public implementationContract;

	/**
	 * @dev Events being fired when the implementation contract is updated
	 */
	event ImplementationUpdated(address indexed newImplementation);

	/**
	 * @dev Initializes the token factory
	 * @param _implementationContract address of the master implementation proxies will point to
	 */
	constructor(address _implementationContract)
		public
		OpenZeppelinUpgradesOwnable()
	{
		implementationContract = _implementationContract;
	}

	/**
	 * @dev Updates the token factory
	 * @param _implementationContract address of the new master implementation proxies will point to
	 */
	function updateImplementation(address _implementationContract)
		public
		onlyOwner
	{
		implementationContract = _implementationContract;
		emit ImplementationUpdated(_implementationContract);
	}

	/**
	 * @dev Deploys a new security token proxy contract
	 * @param _salt random number used to precalculate the contract's address
	 * @param _admin address of the proxy administrator (able to update implementation)
	 * @param _data Data to send as msg.data to the implementation to initialize the proxied contract
	 */
	function deployNewFiatToken(
		uint256 _salt,
		address _admin,
		bytes memory _data
	) public returns (address proxy) {
		return deploy(_salt, implementationContract, _admin, _data);
	}
}