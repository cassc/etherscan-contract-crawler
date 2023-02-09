// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Multicallable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Allows for batched calls (non-payable)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) external {
        unchecked {
            for (uint256 i; i < data.length; ++i) {
                (bool success,) = address(this).delegatecall(data[i]);

                if (!success) {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        }
    }
}