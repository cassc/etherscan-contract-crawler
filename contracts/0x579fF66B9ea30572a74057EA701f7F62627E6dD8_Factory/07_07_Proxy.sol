// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Proxy
 * @notice Basic proxy that delegates all calls to a fixed implementing contract.
 * The implementing contract cannot be upgraded.
 */
contract Proxy {

    address immutable public implementation;

    /**
     * @param _implementation deployed instance of base vault.
     */
    constructor(address _implementation) {
        implementation = _implementation;
    }

    function _fallback() internal {
        address target = implementation;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}