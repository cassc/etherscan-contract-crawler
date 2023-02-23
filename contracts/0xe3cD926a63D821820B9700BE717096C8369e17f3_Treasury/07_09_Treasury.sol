// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./access/Governable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Treasury is Governable {
    using SafeERC20 for IERC20;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    event Withdraw(address indexed token, address indexed to, uint256 amount);

    //solhint-disable no-empty-blocks
    receive() external payable {}

    function withdraw(address token_, address to_, uint256 amount_) external onlyGovernor {
        require(token_ != address(0), "token-is-null");
        require(to_ != address(0), "to-is-null");

        if (token_ == ETH) {
            _withdrawETH(to_, amount_);
        } else {
            _withdrawToken(token_, to_, amount_);
        }
    }

    function _withdrawETH(address to_, uint256 amount_) private {
        uint256 _ethBalance = address(this).balance;
        if (amount_ == type(uint256).max) {
            amount_ = _ethBalance;
        } else {
            require(amount_ <= _ethBalance, "invalid-eth-amount");
        }
        Address.sendValue(payable(to_), amount_);
        emit Withdraw(ETH, to_, amount_);
    }

    function _withdrawToken(address token_, address to_, uint256 amount_) private {
        uint256 _balance = IERC20(token_).balanceOf(address(this));
        if (amount_ == type(uint256).max) {
            amount_ = _balance;
        } else {
            require(amount_ <= _balance, "invalid-token-amount");
        }
        IERC20(token_).safeTransfer(to_, amount_);
        emit Withdraw(token_, to_, amount_);
    }
}