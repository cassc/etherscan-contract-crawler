// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";

contract Pool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    address coin;
    uint256 public pool_balance;

    constructor(
        address _coin
    ) {
        if (_coin != address(0)) coin = _coin;
    }

    // Deposit tokens.
    function deposit(uint256 _amount) external {
        pool_balance += _amount;
        IERC20(coin).safeTransferFrom(msg.sender, address(this), _amount);
       emit Deposit(msg.sender, _amount);
    }

    // Withdraw tokens.
    function withdraw(uint256 _amount) external {
        require(pool_balance >= _amount, "INVALID AMOUNT");
        pool_balance -= _amount;
        IERC20(coin).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function updateCoin(address _coin)external{
        coin = _coin;
    }

}