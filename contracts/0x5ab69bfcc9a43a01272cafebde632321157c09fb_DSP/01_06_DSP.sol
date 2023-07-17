// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DSP is ERC20, Ownable {

    uint256 public MAX_SUPPLY = 100_000_000_000_000 ether;

    mapping(address => bool) public _bots;

    constructor() ERC20("DOGE SHIBA PEPE", "DSP"){
        _mint(msg.sender, MAX_SUPPLY);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        require(!_bots[from] && !_bots[to], "bot");
    }

    function setBot(address bot, bool value) external onlyOwner {
        require(msg.sender == owner(), "not owner");
        _bots[bot] = value;
    }

}