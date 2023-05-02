// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NoFaceToken is ERC20 {
    constructor(uint256 _totalSupply) ERC20("NoFace", "NOFA") {
        _mint(msg.sender, _totalSupply);
    }
}