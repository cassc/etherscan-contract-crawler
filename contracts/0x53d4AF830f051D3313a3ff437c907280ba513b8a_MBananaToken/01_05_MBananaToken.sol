//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MULTIDRIP20} from "./DRIP20/MULTIDRIP20.sol";
import {console} from "./console-std/console.sol";

contract MBananaToken is Ownable, MULTIDRIP20 {
    error NotOwnerOrMonkeVoyagerContract();

    address public monkeVoyagerAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) MULTIDRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

    /*==============================================================
    ==                    Dripping Functions                      ==
    ==============================================================*/

    /**
     * @dev only Monke main contract can start dripping tokens (on mint or transfer).
     * owner can override and start dripping if theres any issue.
     * will remove ownership when not needed so extra tokens cannot be arbitrarily dripped.
     */
    function startHarvest(address addr, uint256 multiplier) external {
        if (msg.sender != monkeVoyagerAddress && msg.sender != owner())
            revert NotOwnerOrMonkeVoyagerContract();
        _startDripping(addr, multiplier);
    }

    /**
     * @dev only Monke main contract can stop dripping tokens (on burn or transfer).
     * owner can override and stop dripping if theres any issue.
     * will remove ownership when not needed so tokens cannot be arbitrarily stopped.
     */
    function stopHarvest(address addr, uint256 multiplier) external {
        if (msg.sender != monkeVoyagerAddress && msg.sender != owner())
            revert NotOwnerOrMonkeVoyagerContract();

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

    function setMonkeVoyagerAddress(address _monkeVoyagerAddress)
        external
        onlyOwner
    {
        monkeVoyagerAddress = _monkeVoyagerAddress;
    }

}