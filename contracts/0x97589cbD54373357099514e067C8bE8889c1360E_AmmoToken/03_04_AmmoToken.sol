//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import {GIGADRIP20} from "./GIGADRIP20.sol";

contract AmmoToken is Ownable, GIGADRIP20 {
    error NotOwnerOrBanditsContract();

    address public onChainBandits;

    constructor() GIGADRIP20("AMMO", "AMMO", 18, 1670000000000000) {}

    /*==============================================================
    ==                    Dripping Functions                      ==
    ==============================================================*/

    /**
     * @dev only bandits can start dripping tokens (on mint or transfer).
     * owner can override and start dripping if theres any issue.
     * will remove ownership when not needed so extra tokens cannot be arbitrarily dripped.
     */
    function startDripping(address addr, uint128 multiplier) external {
        if (msg.sender != onChainBandits && msg.sender != owner())
            revert NotOwnerOrBanditsContract();
        _startDripping(addr, multiplier);
    }

    /**
     * @dev only bandits can stop dripping tokens (on burn or transfer).
     * owner can override and stop dripping if theres any issue.
     * will remove ownership when not needed so tokens cannot be arbitrarily stopped.
     */
    function stopDripping(address addr, uint128 multiplier) external {
        if (msg.sender != onChainBandits && msg.sender != owner())
            revert NotOwnerOrBanditsContract();

        _stopDripping(addr, multiplier);
    }

    function burn(address from, uint256 value) external {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - value;

        _burn(from, value);
    }

    /*==============================================================
    ==                    Only Owner Functions                    ==
    ==============================================================*/

    /**
     * @dev mint tokens to desired address.
     * may be used for prize pools, DEX liquidity, etc.
     * will remove ownership when not needed so extra tokens cannot be minted.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setOnChainBandits(address onChainBanditsAddress)
        external
        onlyOwner
    {
        onChainBandits = onChainBanditsAddress;
    }
}