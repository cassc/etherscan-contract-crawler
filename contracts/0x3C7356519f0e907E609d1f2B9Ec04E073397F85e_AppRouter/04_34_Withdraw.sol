//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../utils/SafeERC20.sol";

contract Withdraw is Ownable, ReentrancyGuard {
    event Withdrawal(address indexed sender, uint256 amount);
    event WithdrawETH(address indexed sender, uint256 amount);

    function withdrawToken(
        IERC20 token,
        address _to,
        uint256 _value
    ) public onlyOwner nonReentrant {
        require(token.balanceOf(address(this)) >= _value, "Not enough token");
        SafeERC20.safeTransfer(token, _to, _value);
        emit Withdrawal(_to, _value);
    }

    function getEthBalance() public view returns (uint256 amount) {
        return address(this).balance;
    }

    function withdrawETH(uint256 amount) public onlyOwner nonReentrant {
        require(amount <= getEthBalance(), "Not enough ETH");
        payable(msg.sender).transfer(amount);
        emit WithdrawETH(msg.sender, amount);
    }
}