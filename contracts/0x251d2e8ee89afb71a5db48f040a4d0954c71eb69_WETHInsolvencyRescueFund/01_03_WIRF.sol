// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WETHInsolvencyRescueFund is Ownable {

    receive() external payable { }
    fallback() external payable { }

    function rescueWETH() external onlyOwner {
        selfdestruct(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    }
}