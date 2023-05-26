// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Withdrawable is Ownable {
    using SafeERC20 for IERC20;

    constructor() {
        // _transferOwnership(0x6FA6DA462CBA635b0193809332387cDC25Df3e8D);
    }

    function withdrawBNB() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawToken(address token, uint value) external onlyOwner {
        require(
            IERC20(token).balanceOf(address(this)) >= value,
            "Not enough tokens"
        );
        require(IERC20(token).transfer(msg.sender, value));
    }
}