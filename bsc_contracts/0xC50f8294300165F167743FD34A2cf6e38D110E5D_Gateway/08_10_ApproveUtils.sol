// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library ApproveUtils {
        using Address for address;
        using SafeERC20 for IERC20;

        function safeApproveImproved(IERC20 token, address spender, uint256 requiredAmount) internal {
                uint256 allowance = token.allowance(address(this), spender);

                if (allowance >= requiredAmount) return;

                if (allowance == 0) {
                        token.safeApprove(spender, requiredAmount);
                        return;
                }

                try token.approve(spender, requiredAmount) returns (bool result) {
                        require(result, 'failed to approve spender');
                } catch {

                        token.safeApprove(spender, 0);
                        token.safeApprove(spender, requiredAmount);
                }
        }

        function zeroAllowance(IERC20 token, address spender) internal {
                if (token.allowance(address(this), spender) == 0) return;

                token.safeApprove(spender, 0);

                require(token.allowance(address(this), spender) == 0, 'failed to zero allowance');
        }
}