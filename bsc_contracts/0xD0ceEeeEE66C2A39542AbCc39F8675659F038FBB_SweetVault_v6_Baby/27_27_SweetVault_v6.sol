/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable-v4/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./SweetVault_v5.sol";

contract SweetVault_v6 is SweetVault_v5 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function withdrawAndUnZap(
        UnZapInfo memory _unZapInfo,
        address _outputToken
    ) external virtual nonReentrant {
        uint initialStakedTokenBalance = _currentBalance(_unZapInfo.inputToken);

        _withdraw(_unZapInfo.inputTokenAmount, address(this));

        uint profit = _currentBalance(_unZapInfo.inputToken) - initialStakedTokenBalance;

        IERC20Upgradeable(_unZapInfo.inputToken).approve(zap, profit);

        _unZapInfo.inputTokenAmount = profit;

        if (_outputToken == address(0)) {
            uint initialOutputTokenBalance = address(this).balance;

            IPeanutZap(zap).unZapNative(_unZapInfo);

            payable(msg.sender).transfer(address(this).balance - initialOutputTokenBalance);
        } else {
            uint initialOutputTokenBalance = _currentBalance(_outputToken);

            IPeanutZap(zap).unZapToken(_unZapInfo, _outputToken);

            IERC20Upgradeable(_outputToken).safeTransfer(
                msg.sender,
                _currentBalance(_outputToken) - initialOutputTokenBalance
            );
        }
    }

    function withdraw(uint _amount) external override virtual nonReentrant {
        _withdraw(_amount, msg.sender);
    }

    function _withdraw(uint _amount, address _to) internal virtual {
        UserInfo storage user = userInfo[msg.sender];
        address stakedToken = farmInfo.stakedToken;

        require(_amount > 0, "SweetVault: amount must be greater than zero");
        require(user.stake >= _amount, "SweetVault: withdraw amount exceeds balance");

        uint currentAmount = _withdrawUnderlying(_amount);

        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            uint currentWithdrawFee = (currentAmount * earlyWithdrawFee) / 10000;

            IERC20Upgradeable(stakedToken).safeTransfer(authority.treasury(), currentWithdrawFee);

            currentAmount = currentAmount - currentWithdrawFee;

            emit EarlyWithdraw(msg.sender, _amount, currentWithdrawFee);
        }

        _updateAutoPacocaShares(user);
        user.stake = user.stake - _amount;
        _updateRewardDebt(user);

        // Withdraw pacoca rewards if user leaves
        if (user.stake == 0 && user.autoPacocaShares > 0) {
            _claimRewards(user.autoPacocaShares, false);
        }

        IERC20Upgradeable(stakedToken).safeTransfer(_to, currentAmount);

        emit Withdraw(msg.sender, currentAmount);
    }

    receive() external payable {}
}