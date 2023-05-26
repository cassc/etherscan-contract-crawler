// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Simulation is ERC20, ERC20Burnable, Ownable {
    uint256 totalSIMS = 420000000000 * 10 ** decimals();
    constructor( address  cexWallet_,  address marketing_) ERC20("Simulation", "SIMS") {
        _mint(msg.sender, (totalSIMS) * 900 / 1000); // 90% liquidity
        _mint(marketing_, (totalSIMS) * 30 / 1000); // 3% marketing wallet
        _mint(cexWallet_, (totalSIMS) * 70 / 1000); // 7% cex wallet
    }
}