// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title ergonomic and robust utility functions to set and reset allowances in a safe way
library ApproveUtils {
        using Address for address;
        using SafeERC20 for IERC20;

        /// @notice ERC20 safeApprove
        /// @dev Gives `spender` allowance to transfer `requiredAmount` of `token` held by this contract
        function safeApproveImproved(IERC20 token, address spender, uint256 requiredAmount) internal {
                uint256 allowance = token.allowance(address(this), spender);

                // only change allowance if we don't have enough of it already
                if (allowance >= requiredAmount) return;

                if (allowance == 0) {
                        // safeApprove works only if trying to set to 0 or current allowance is 0
                        token.safeApprove(spender, requiredAmount);
                        return;
                }

                // current allowance != 0 and less than the required amount
                // first try to set it to the required amount
                try token.approve(spender, requiredAmount) returns (bool result) {
                        // check return status safeApprove() does this for us, but not approve()
                        require(result, 'failed to approve spender');
                } catch {
                        // Probably a non standard ERC20, like USDT

                        // set allowance to 0
                        token.safeApprove(spender, 0);
                        // set allowance to required amount
                        token.safeApprove(spender, requiredAmount);
                }
        }

        /// @dev Reset ERC20 allowance to 0
        function zeroAllowance(IERC20 token, address spender) internal {
                // if already 0 don't do anything (can't be less than 0 because uint)
                if (token.allowance(address(this), spender) == 0) return;

                token.safeApprove(spender, 0);

                require(token.allowance(address(this), spender) == 0, 'failed to zero allowance');
        }
}