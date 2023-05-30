// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ClaimRewards is Ownable {
    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function claim() public payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}