// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Bubbles is ERC20("Bubbles", "BUBBLE"), Ownable {
    mapping(address => bool) public minters;

    constructor() {}

    function mint(address recipient, uint amount) external {
        require(minters[msg.sender], "Not approved to mint");
        _mint(recipient, amount);
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }

    function setMinter(address addr, bool val) external onlyOwner {
        minters[addr] = val;
    }
}