// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// RaeMundo is an orca who always takes care of his pod. You come to him with some RAE, and leave with more RAE! The longer you are part of RaeMundo's pod, there more RAE you will get
// This contract handles swapping to and from xRAE, RAE's staking token.
contract RaeMundo is ERC20("RaeMundo", "xRAE"){
    using SafeMath for uint256;
    IERC20 public rae;

    // Define the rae token contract
    constructor(IERC20 _rae) public {
        rae = _rae;
    }

    // Join the pod. Pay some RAE. Earn some xRAE.
    // Locks RAE and mints xRAE 
    function enter(uint256 _amount) public {
        // Gets the amount of RAE locked in the contract
        uint256 totalRae = rae.balanceOf(address(this));
        // Gets the amount of xRAE in existence
        uint256 totalShares = totalSupply();
        // If no xRAE exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalRae == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xRAE the RAE is worth. The ratio will change overtime, as xRAE is burned/minted and RAE
        // deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalRae);
            _mint(msg.sender, what);
        }
        // Lock the RAE in the contract
        rae.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the pod. Claim back your RAE.
    // Unlocks the staked + gained RAE and burns xRAE
    function leave(uint256 _share) public {
        // Gets the amount of xRAE in existence
        uint256 totalShares = totalSupply();

        // Calculates the amount of RAE the xRAE is worth
        uint256 what = _share.mul(rae.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, _share);
        rae.transfer(msg.sender, what);
    }
}