// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../SimplePosition/SimplePositionStorage.sol';
import '../FoldingAccount/FoldingAccountStorage.sol';

contract FundsManager is FoldingAccountStorage, SimplePositionStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 internal constant MANTISSA = 1e18;

    uint256 public immutable principal;
    uint256 public immutable profit;
    address public immutable holder;

    event FundsWithdrawal(uint256 withdrawAmount, uint256 principalFactor);

    constructor(
        uint256 _principal,
        uint256 _profit,
        address _holder
    ) public {
        require(_principal < MANTISSA, 'ICP1');
        require(_profit < MANTISSA, 'ICP1');
        require(_holder != address(0), 'ICP0');
        principal = _principal;
        profit = _profit;
        holder = _holder;
    }

    function addPrincipal(uint256 amount) internal {
        IERC20(simplePositionStore().supplyToken).safeTransferFrom(accountOwner(), address(this), amount);
        simplePositionStore().principalValue += amount;
    }

    function withdraw(uint256 amount, uint256 positionValue) internal {
        SimplePositionStore memory sp = simplePositionStore();

        uint256 principalFactor = positionValue == 0 ? MANTISSA : sp.principalValue.mul(MANTISSA).div(positionValue);

        uint256 principalShare = amount;
        uint256 profitShare;

        if (principalFactor < MANTISSA) {
            principalShare = amount.mul(principalFactor) / MANTISSA;
            profitShare = amount.sub(principalShare);
        }

        uint256 subsidy = principalShare.mul(principal).add(profitShare.mul(profit)) / MANTISSA;

        if (sp.principalValue > principalShare) {
            simplePositionStore().principalValue = sp.principalValue - principalShare;
        } else {
            simplePositionStore().principalValue = 0;
        }

        IERC20(sp.supplyToken).safeTransfer(holder, subsidy);
        IERC20(sp.supplyToken).safeTransfer(accountOwner(), amount.sub(subsidy));
        emit FundsWithdrawal(amount, principalFactor);
    }
}