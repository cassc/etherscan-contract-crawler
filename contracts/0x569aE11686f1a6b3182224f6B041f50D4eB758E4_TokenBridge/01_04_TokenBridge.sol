// contracts/TokenBridge.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Governable.sol";

contract TokenBridge is Governable {

    event Deposit(address indexed src, uint256 amount, address indexed token);
    event Withdrawal(address indexed src, uint256 amount, address indexed token);

    function deposit(uint256 amount, address token) public {
        require (amount > 0, "!amount");
        require (IERC20(token).transferFrom(_msgSender(), address(this), amount), "!transfer");
        emit Deposit(_msgSender(), amount, token);
    }

    function withdraw(address to, uint256 amount, address token) public onlyGovernance {
        require (amount > 0, "!amount");
        require (IERC20(token).balanceOf(address(this)) >= amount, "!balance");
        require (IERC20(token).transfer(to, amount), "!transfer");
        emit Withdrawal(to, amount, token);
    }
}