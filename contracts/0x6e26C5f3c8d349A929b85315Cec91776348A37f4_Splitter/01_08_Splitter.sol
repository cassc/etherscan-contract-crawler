// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Splitter is ReentrancyGuard, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    struct Balance {
        address receiver;
        uint256 amount;
    }

    constructor() {}

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function batchSendToken(address _token, Balance[] memory balances) external nonReentrant {
        IERC20 token = IERC20(_token);
        for (uint256 i = 0; i < balances.length; i++) {
            token.safeTransferFrom(msg.sender, balances[i].receiver, balances[i].amount);
        }
    }

    function batchSendETH(Balance[] memory balances) external payable nonReentrant {
        for (uint256 i = 0; i < balances.length; i++) {
            (bool sent, ) = payable(balances[i].receiver).call{ value: balances[i].amount }("");
            require(sent, "Failed to send Ether");
        }
    }

    function approve(address _token, uint256 value) external {
        IERC20 token = IERC20(_token);
        token.safeApprove(address(this), value);
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool sent, ) = payable(msg.sender).call{ value: balance }("");
        require(sent, "Failed to send Ether");
    }
}