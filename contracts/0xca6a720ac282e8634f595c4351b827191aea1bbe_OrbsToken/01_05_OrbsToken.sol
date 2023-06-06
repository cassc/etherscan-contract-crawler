// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝

///@author 0xBeans
///@dev This contract contains dripping $ORBS implementation

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {GIGADRIP20} from "DRIP20/GIGADRIP20.sol";
import {console} from "forge-std/console.sol";

contract OrbsToken is Ownable, GIGADRIP20 {
    error NotOwnerOrScrollsContract();

    address public mirakaiScrolls;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) GIGADRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

    /*==============================================================
    ==                    Dripping Functions                      ==
    ==============================================================*/

    /**
     * @dev only scrolls can start dripping tokens (on mint or transfer).
     * owner can override and start dripping if theres any issue.
     * will remove ownership when not needed so extra tokens cannot be arbitrarily dripped.
     */
    function startDripping(address addr, uint128 multiplier) external {
        if (msg.sender != mirakaiScrolls && msg.sender != owner())
            revert NotOwnerOrScrollsContract();
        _startDripping(addr, multiplier);
    }

    /**
     * @dev only scrolls can stop dripping tokens (on burn or transfer).
     * owner can override and stop dripping if theres any issue.
     * will remove ownership when not needed so tokens cannot be arbitrarily stopped.
     */
    function stopDripping(address addr, uint128 multiplier) external {
        if (msg.sender != mirakaiScrolls && msg.sender != owner())
            revert NotOwnerOrScrollsContract();

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

    function setmirakaiScrolls(address mirakaiScrollsAddress)
        external
        onlyOwner
    {
        mirakaiScrolls = mirakaiScrollsAddress;
    }
}