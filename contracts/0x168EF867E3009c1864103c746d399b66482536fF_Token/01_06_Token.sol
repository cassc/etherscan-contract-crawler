// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
    @title Token that used to create Proof of Burn
    @author Toshi - http://github.com/toshiSat
    @notice This is just an ERC20 token that is burnable and mints it's initial supply on launch
*/
contract Token is ERC20, ERC20Burnable {
    constructor(uint256 _supply) ERC20("KeepKey Open Development Initiative", "KODI") {
        _mint(msg.sender, _supply); // mint entire supply to msg.sender
    }
}