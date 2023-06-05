// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@safe/proxies/GnosisSafeProxyFactory.sol";
import "@safe/proxies/GnosisSafeProxy.sol";
import "@safe/GnosisSafe.sol";

import "@pwn-safe/factory/IPWNSafeValidator.sol";


/**
 * @title PWNSafe Factory
 * @notice Contract that deploys new PWNSafes and keep track of deployed addresses.
 */
contract PWNSafeFactory is IPWNSafeValidator {

	/*----------------------------------------------------------*|
	|*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
	|*----------------------------------------------------------*/

	string public constant VERSION = "0.1.0";

	bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;
	address internal constant SENTINEL_MODULES = address(0x1);

	address internal immutable pwnFactorySingleton;
	address internal immutable gnosisSafeSingleton;
	GnosisSafeProxyFactory internal immutable gnosisSafeProxyFactory;
	address internal immutable fallbackHandler;
	address internal immutable atrModule;
	address internal immutable atrGuard;

	/**
	 * @dev Mapping of valid PWNSafe addresses. Is set on safe deployment.
	 *      (safe address -> isValid)
	 */
	mapping (address => bool) public isValidSafe;


	/*----------------------------------------------------------*|
	|*  # EVENTS & ERRORS DEFINITIONS                           *|
	|*----------------------------------------------------------*/

	event PWNSafeDeployed(address indexed safe);


	/*----------------------------------------------------------*|
	|*  # CONSTRUCTOR                                           *|
	|*----------------------------------------------------------*/

	constructor(
		address _gnosisSafeSingleton,
		address _gnosisSafeProxyFactory,
		address _fallbackHandler,
		address _atrModule,
		address _atrGuard
	) {
		pwnFactorySingleton = address(this);

		require(_gnosisSafeSingleton != address(0), "Safe signleton is zero address");
		gnosisSafeSingleton = _gnosisSafeSingleton;

		require(_gnosisSafeProxyFactory != address(0), "Safe proxy factory is zero address");
		gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);

		require(_fallbackHandler != address(0), "Fallback handler is zero address");
		fallbackHandler = _fallbackHandler;

		require(_atrModule != address(0), "ATR module is zero address");
		atrModule = _atrModule;

		require(_atrGuard != address(0), "ATR guard is zero address");
		atrGuard = _atrGuard;
	}


	/*----------------------------------------------------------*|
	|*  # DEPLOY PROXY                                          *|
	|*----------------------------------------------------------*/

	/**
	 * @dev Deploy new PWNSafe proxy and set AssetTransferRightsGuard, AssetTransferRights module and fallback handler.
	 *      Guard, module and fallback handler have to be set on deployment and cannot be changed afterwards,
	 *      otherwise it would be possible for an owner to set allowance for several addresses,
 	 *      setup PWNSafe and then transfer them without proper transfer rights.
 	 * @param owners List of PWNSafe owners
 	 * @param threshold Number of required owner confirmations
 	 * @return Address of a newly deployed GnosisSafe proxy set with proper guard, module and fallback handler
	 */
	function deployProxy(
		address[] calldata owners,
		uint256 threshold
	) external returns (GnosisSafe) {
		// Deploy new gnosis safe proxy
		GnosisSafeProxy proxy = gnosisSafeProxyFactory.createProxy(gnosisSafeSingleton, "");
		GnosisSafe safe = GnosisSafe(payable(address(proxy)));

		// Setup safe
		safe.setup(
			owners, // _owners
			threshold, // _threshold
			address(this), // to
			abi.encodeWithSelector(PWNSafeFactory.setupNewSafe.selector), // data
			fallbackHandler, // fallbackHandler
			address(0), // paymentToken
			0, // payment
			payable(address(0)) // paymentReceiver
		);

		// Store as valid address
		isValidSafe[address(safe)] = true;

		// Emit event
		emit PWNSafeDeployed(address(safe));

		return safe;
	}


	/*----------------------------------------------------------*|
	|*  # NEW SAFE SETUP                                        *|
	|*----------------------------------------------------------*/

	/**
	 * @dev Function that sets AssetTransferRightsGuard, AssetTransferRights module and fallback handler.
	 *      Is ment to be called only by PWNSafeFactory after PWNSafe deployment.
	 *      Attempt to setup PWNSafe via this function will fail as it would not set safes address as valid.
	 */
	function setupNewSafe() external {
		// Check that is called via delegatecall
		require(address(this) != pwnFactorySingleton, "Should only be called via delegatecall");

		// Check that caller is GnosisSafeProxy
		// Need to hash bytes arrays first, because solidity cannot compare byte arrays directly
		require(keccak256(gnosisSafeProxyFactory.proxyRuntimeCode()) == keccak256(address(this).code), "Caller is not gnosis safe proxy");

		// Check that proxy has correct singleton set
		// GnosisSafeStorage.sol defines singleton address at the first position (-> index 0)
		bytes memory singletonValue = StorageAccessible(address(this)).getStorageAt(0, 1);
		require(bytes32(singletonValue) == bytes32(uint256(uint160(gnosisSafeSingleton))), "Proxy has unsupported singleton");

		_storeGuardAndModule();
	}

	function _storeGuardAndModule() private {
		// GnosisSafeStorage.sol defines modules mapping at the second position (-> index 1)
		bytes32 atrModuleSlot = keccak256(abi.encode(atrModule, uint256(1)));
		address atrModuleAddress = atrModule;

		// GnosisSafeStorage.sol defines modules mapping at the second position (-> index 1)
		bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULES, uint256(1)));
		address sentinelAddress = SENTINEL_MODULES;

		bytes32 guardSlot = GUARD_STORAGE_SLOT;
		address atrGuardAddress = atrGuard;

		assembly {
			// Enable new module
			sstore(sentinelSlot, atrModuleAddress) // SENTINEL_MODULES key should have value of module address
			sstore(atrModuleSlot, sentinelAddress) // module address key should have value of SENTINEL_MODULES

			// Set guard
			sstore(guardSlot, atrGuardAddress)
		}
	}

}