// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

//import "../actions/MixinActions.sol";
import "../immutable/MixinImmutables.sol";
import "../immutable/MixinStorage.sol";
import "../../interfaces/IAuthority.sol";

abstract contract MixinFallback is MixinImmutables, MixinStorage {
    // reading immutable through internal method more gas efficient
    modifier onlyDelegateCall() {
        _checkDelegateCall();
        _;
    }

    /* solhint-disable no-complex-fallback */
    /// @inheritdoc IRigoblockV3PoolFallback
    fallback() external payable {
        address adapter = _getApplicationAdapter(msg.sig);
        // we check that the method is approved by governance
        require(adapter != address(0), "POOL_METHOD_NOT_ALLOWED_ERROR");

        // direct fallback to implementation will result in staticcall to extension as implementation owner is address(1)
        address poolOwner = pool().owner;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success
            // pool owner can execute a delegatecall to extension, any other caller will perform a staticcall
            if eq(caller(), poolOwner) {
                success := delegatecall(gas(), adapter, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                if eq(success, 0) {
                    revert(0, returndatasize())
                }
                return(0, returndatasize())
            }
            success := staticcall(gas(), adapter, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            // we allow the staticcall to revert with rich error, should we want to add errors to extensions view methods
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /* solhint-enable no-complex-fallback */

    /// @inheritdoc IRigoblockV3PoolFallback
    receive() external payable onlyDelegateCall {}

    function _checkDelegateCall() private view {
        require(address(this) != _implementation, "POOL_IMPLEMENTATION_DIRECT_CALL_NOT_ALLOWED_ERROR");
    }

    /// @dev Returns the address of the application adapter.
    /// @param selector Hash of the method signature.
    /// @return Address of the application adapter.
    function _getApplicationAdapter(bytes4 selector) private view returns (address) {
        return IAuthority(authority).getApplicationAdapter(selector);
    }
}