// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';

contract TreasuryVester {
    using SafeMath for uint256;

    address public dydx;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address dydx_,
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) {
        require(vestingBegin_ >= block.timestamp, 'VESTING_BEGIN_TOO_EARLY');
        require(vestingCliff_ >= vestingBegin_, 'VESTING_CLIFF_BEFORE_BEGIN');
        require(vestingEnd_ > vestingCliff_, 'VESTING_END_BEFORE_CLIFF');

        dydx = dydx_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'SET_RECIPIENT_UNAUTHORIZED');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'CLAIM_TOO_EARLY');
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IDydx(dydx).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IDydx(dydx).transfer(recipient, amount);
    }
}

interface IDydx {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address dst, uint256 rawAmount) external returns (bool);
}