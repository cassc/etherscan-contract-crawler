// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Withdrawable is Ownable {

    function withdrawEther() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}