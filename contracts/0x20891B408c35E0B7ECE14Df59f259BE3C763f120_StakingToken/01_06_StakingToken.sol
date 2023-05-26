// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Adapted from Sushi's SushiBar by CitaDAO with very minor changes
// - compiler version updated to 0.8.0
// - remove unnecessary public visibility from constructor
// - rename sushi -> knight
// - rename to StakingToken
// - change name and symbol
//
// Original description
// "SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get."
//
// This contract handles swapping to and from xKNIGHT, CitaDAO's staking token.
contract StakingToken is ERC20("CitaDAO Staking", "xKNIGHT") {
    using SafeMath for uint256;
    IERC20 public knight;

    // Define the Knight token contract
    constructor(IERC20 _knight) {
        knight = _knight;
    }

    // Enter the bar. Pay some KNIGHTs. Earn some shares.
    // Locks Knight and mints xKnight
    function enter(uint256 _amount) public {
        // Gets the amount of Knight locked in the contract
        uint256 totalKnight = knight.balanceOf(address(this));
        // Gets the amount of xKnight in existence
        uint256 totalShares = totalSupply();
        // If no xKnight exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalKnight == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xKnight the Knight is worth. The ratio will change overtime, as xKnight is burned/minted and Knight deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalKnight);
            _mint(msg.sender, what);
        }
        // Lock the Knight in the contract
        knight.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your KNIGHTs.
    // Unlocks the staked + gained Knight and burns xKnight
    function leave(uint256 _share) public {
        // Gets the amount of xKnight in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Knight the xKnight is worth
        uint256 what = _share.mul(knight.balanceOf(address(this))).div(
            totalShares
        );
        _burn(msg.sender, _share);
        knight.transfer(msg.sender, what);
    }
}