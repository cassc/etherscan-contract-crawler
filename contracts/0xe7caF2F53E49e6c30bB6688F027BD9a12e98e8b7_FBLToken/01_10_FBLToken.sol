// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// FBLToken
contract FBLToken is ERC20Snapshot, Ownable {
    constructor(uint256 initialSupply) ERC20("FinTech Blockchain", "FBL") {
        _mint(msg.sender, initialSupply);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }
}