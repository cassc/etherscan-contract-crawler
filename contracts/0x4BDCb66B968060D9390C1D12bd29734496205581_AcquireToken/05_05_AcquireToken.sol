/**
 * 🄰🄲🅀🅄🄸🅁🄴.🄵🄸
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AcquireToken is ERC20 {
    constructor(address mintToWallet, uint256 initialSupply) ERC20("Acquire.Fi", "ACQ") {
        _mint(mintToWallet, initialSupply);
    }
}