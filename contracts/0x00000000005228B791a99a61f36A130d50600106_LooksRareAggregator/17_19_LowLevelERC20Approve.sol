// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC20} from "../interfaces/generic/IERC20.sol";

// Errors
import {ERC20ApprovalFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC20Approve
 * @notice This contract contains low-level calls to approve ERC20 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC20Approve {
    /**
     * @notice Execute ERC20 approve
     * @param currency Currency address
     * @param to Operator address
     * @param amount Amount to approve
     */
    function _executeERC20Approve(address currency, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.approve, (to, amount)));

        if (!status) {
            revert ERC20ApprovalFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20ApprovalFail();
            }
        }
    }
}