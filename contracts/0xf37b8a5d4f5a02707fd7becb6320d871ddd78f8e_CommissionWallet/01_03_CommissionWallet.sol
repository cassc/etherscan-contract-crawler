// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommissionWallet is Ownable {
    event Transfer(address indexed from, address to, uint amount);

    function withdraw() external onlyOwner {
        emit Transfer(address(this), msg.sender, address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        emit Transfer(msg.sender, address(this), msg.value);
    }
}