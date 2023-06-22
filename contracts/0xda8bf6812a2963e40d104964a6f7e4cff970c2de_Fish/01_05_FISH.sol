// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fish is ERC20 {
    uint256 private _totalSupply = 21000000 * (10 ** 18);

    constructor() ERC20("Fish Token", "FISH", 0x2E6B60F87aBbf2Bba8B2DBb3d3f2946b37Ed92E8, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

    uint256 public _fee = 0;
    address public swapper;
}