// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBalanceController.sol";

// BalanceController is an `Ownable` contract that can receive coins, and in
// which the owner has the ability to withdraw coins and tokens arbitrarily.
contract BalanceController is IBalanceController, Ownable {
    receive() external payable override {}

    function withdrawToken(address token, address account, uint256 amount) external override onlyOwner {
        require(IERC20(token).transfer(account, amount), 'BalanceController: withdrawToken failed.');
    }

    function withdrawEth(address account, uint256 amount) external override onlyOwner {
        (bool sent,) = account.call{value : amount}('');
        require(sent, 'BalanceController: withdrawEth failed.');
    }
}