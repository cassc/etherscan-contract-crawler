/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract WithTreasury {
    /// @dev modaTreasury will receive a percentage of all final sales to support the ecosystem
    address payable public modaTreasury;

    /// @dev treasuryFee is based on a denominator of 10,000 (e.g. 1000 is 10.0%). Max of 10%
    uint256 public treasuryFee;

    event TreasuryFeeSet(uint256 oldFee, uint256 newFee);
    event Treasury(address indexed oldTreasury, address indexed newTreasury);

    constructor(address payable modaTreasury_, uint256 treasuryFee_) {
        require(address(0) != modaTreasury_, "Treasury cannot be 0x0");

        _setTreasury(modaTreasury_);
        _setTreasuryFee(treasuryFee_);
    }

    function _setTreasury(address payable newTreasury) internal {
        address old = modaTreasury;
        modaTreasury = newTreasury;
        emit Treasury(old, newTreasury);
    }

    function _setTreasuryFee(uint256 newFee_) internal {
        require(newFee_ <= 1000, "Cannot be greater than 1000 (10%)");

        uint256 oldFee = treasuryFee;
        treasuryFee = newFee_;
        emit TreasuryFeeSet(oldFee, newFee_);
    }
}