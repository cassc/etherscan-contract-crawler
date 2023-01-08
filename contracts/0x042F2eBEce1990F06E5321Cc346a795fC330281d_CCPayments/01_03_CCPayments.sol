// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CCPayments is Ownable {
    event Deposit(address sender, uint256 etherValue);

    fallback() external payable {}

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}