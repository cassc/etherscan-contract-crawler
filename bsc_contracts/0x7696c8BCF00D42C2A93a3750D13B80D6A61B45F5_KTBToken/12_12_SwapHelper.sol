// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC20.sol";

contract SwapHelper is Ownable {
    address public usdtAddress;

    constructor(address usdt) {
        usdtAddress = usdt;
    }

    function transferToOwner() public onlyOwner {
        IERC20 tokenContract = IERC20(usdtAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), balance);
    }
}
