// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Assembly constants
import {ETHTransferFail_error_selector, ETHTransferFail_error_length, Error_selector_offset} from "../constants/AssemblyConstants.sol";

/**
 * @title LowLevelETHReturnETHIfAnyExceptOneWei
 * @notice This contract contains a function to return all ETH except 1 wei held.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelETHReturnETHIfAnyExceptOneWei {
    /**
     * @notice It returns ETH to the original sender if any is left in the payable call
     *         but this leaves 1 wei of ETH in the contract.
     * @dev It does not revert if self balance is equal to 1 or 0.
     */
    function _returnETHIfAnyWithOneWeiLeft() internal {
        assembly {
            let selfBalance := selfbalance()
            if gt(selfBalance, 1) {
                let status := call(gas(), caller(), sub(selfBalance, 1), 0, 0, 0, 0)
                if iszero(status) {
                    mstore(0x00, ETHTransferFail_error_selector)
                    revert(Error_selector_offset, ETHTransferFail_error_length)
                }
            }
        }
    }
}