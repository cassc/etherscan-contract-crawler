// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BatchTransferERC20 is Ownable {

    constructor() {}

    function batchTransfer(address erc20, address[] calldata to, uint256[] calldata amount) public onlyOwner {
        require(to.length == amount.length, "Invalid arrays");
        for (uint i = 0; i < to.length; i++) {
            IERC20(erc20).transfer(to[i], amount[i]);
        }
    }
}