// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./07_20_SafeERC20Upgradeable.sol";
import "./08_20_IERC20Upgradeable.sol";

import "./12_20_Errors.sol";

library SmartApprove {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function smartApprove(
        address _tokenIn,
        uint256 _amount,
        address _to
    ) internal {
        IERC20Upgradeable tokenIn = IERC20Upgradeable(_tokenIn);
        uint256 _allowance = tokenIn.allowance(address(this), _to);
        if (_allowance < _amount) {
            if (_allowance == 0) {
                tokenIn.safeApprove(_to, type(uint256).max);
            } else {
                try tokenIn.approve(_to, type(uint256).max) returns (bool res) {
                    if (!res) {
                        revert ApproveFailed();
                    }
                } catch {
                    tokenIn.safeApprove(_to, 0);
                    tokenIn.safeApprove(_to, type(uint256).max);
                }
            }
        }
    }
}