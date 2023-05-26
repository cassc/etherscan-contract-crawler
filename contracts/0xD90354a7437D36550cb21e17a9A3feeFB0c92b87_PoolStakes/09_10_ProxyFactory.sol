// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >0.8.0;

/**
 * @title ProxyFactory
 * @notice It "clones" the (child) contract deploying EIP-1167 proxies
 * @dev Generated proxies:
 * - being the EIP-1167 proxy, DELEGATECALL this (child) contract
 * - support EIP-1967 specs for the "implementation slot"
 *  (it gives explorers/wallets more chances to "understand" it's a proxy)
 */
abstract contract ProxyFactory {
    // Storage slot that the EIP-1967 defines for the "implementation" address
    // (`uint256(keccak256('eip1967.proxy.implementation')) - 1`)
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Emits when a new proxy is created
    event NewProxy(address proxy);

    /**
     * @notice Returns `true` if called on a proxy (rather than implementation)
     */
    function isProxy() external view returns (bool) {
        return _isProxy();
    }

    /**
     * @notice Deploys a new proxy instance that DELEGATECALLs this contract
     * @dev Must be called on the implementation (reverts if a proxy is called)
     */
    function createProxy() external returns (address proxy) {
        _throwProxy();

        // CREATE an EIP-1167 proxy instance with the target being this contract
        bytes20 target = bytes20(address(this));
        assembly {
            let initCode := mload(0x40)
            mstore(
                initCode,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(initCode, 0x14), target)
            mstore(
                add(initCode, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            // note, 0x37 (55 bytes) is the init bytecode length
            // while the deployed bytecode length is 0x2d (45 bytes) only
            proxy := create(0, initCode, 0x37)
        }

        // Write this contract address into the proxy' "implementation" slot
        // (reentrancy attack impossible - this contract called)
        ProxyFactory(proxy).initProxy(address(this));

        emit NewProxy(proxy);
    }

    /**
     * @dev Writes given address into the "implementation" slot of a new proxy.
     * !!! It MUST (and may only) be called:
     * - via the implementation instance with the {createProxy} method
     * - on a newly deployed proxy only
     * It reverts if called on the implementation or on initialized proxies.
     */
    function initProxy(address impl) external {
        _throwImplementation();
        require(
            _getImplementation() == address(0),
            "ProxyFactory:ALREADY_INITIALIZED"
        );

        // write into the "implementation" slot
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, impl)
        }
    }

    /// @dev Returns true if called on a proxy instance
    function _isProxy() internal view virtual returns (bool) {
        // for a DELEGATECALLed contract, `this` and `extcodesize`
        // are the address and the code size of the calling contract
        // (for a CALLed contract, they are ones of that called contract)
        uint256 _size;
        address _this = address(this);
        assembly {
            _size := extcodesize(_this)
        }

        // shall be the same as the one the `createProxy` generates
        return _size == 45;
    }

    /// @dev Returns the address stored in the "implementation" slot
    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /// @dev Throws if called on the implementation
    function _throwImplementation() internal view {
        require(_isProxy(), "ProxyFactory:IMPL_CALLED");
    }

    /// @dev Throws if called on a proxy
    function _throwProxy() internal view {
        require(!_isProxy(), "ProxyFactory:PROXY_CALLED");
    }
}