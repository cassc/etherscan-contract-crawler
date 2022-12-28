//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./mixins/ProtocolCompound.sol";

contract BorrowAggregator is ProtocolCompound {
    function deposit(address collateral, uint256 amount) internal {
        _deposit(IERC20(collateral), amount);
    }

    function borrow(address debt, uint256 repayAmount) internal {
        _borrow(IERC20(debt), repayAmount);
    }

    function pnl(
        address collateral,
        address debt,
        uint256 leverageRatio
    ) internal returns (uint256) {
        return (_pnl(IERC20(collateral), IERC20(debt)) * (leverageRatio - 1)) / leverageRatio;
    }

    function repay(address token, uint256 amount) internal {
        _repay(IERC20(token), amount);
    }

    function redeemAll(address token) internal {
        _redeemAll(IERC20(token));
    }
}