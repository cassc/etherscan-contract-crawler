// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

/*
   __  ____           ____               
  /  |/  (_)__  ___  / __/    _____ ____ 
 / /|_/ / / _ \/ _ \_\ \| |/|/ / _ `/ _ \
/_/  /_/_/_//_/\___/___/|__,__/\_,_/ .__/
                                  /_/           
*
* MIT License
* ===========
*
* Copyright (c) 2022 MinoSwap
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IVestingMaster.sol";

contract VestingMaster is IVestingMaster, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // The token being vested.
    IERC20 public override vestingToken;

    // Reward locked info of each user.
    mapping(address => LockedReward) public userLockedRewards;

    // The length of each vesting period.
    uint256 public immutable override period;

    // Number of periods per vesting period.
    uint256 public immutable override lockedPeriodAmount;

    // Total rewards locked in.
    uint256 public override totalLockedRewards;

    // Farms generating Mino
    mapping(address => bool) public override farms;

    // Developer address.
    address public override devAddress;

    /* ========== MODIFIERS ========== */

    modifier onlyFarms() {
        require(
            farms[msg.sender],
            "VestingMaster::onlyFarms: Caller is not a farms"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "VestingMaster::onlyGovernance: Not gov"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _lockedPeriodAmount,
        address _vestingToken,
        address _devAddress
    ) {
        require(
            _vestingToken != address(0),
            "VestingMaster::constructor: Zero address"
        );
        require(_period > 0, "VestingMaster::constructor: Period zero");
        require(
            _lockedPeriodAmount > 0,
            "VestingMaster::constructor: Period amount zero"
        );
        vestingToken = IERC20(_vestingToken);
        period = _period;
        lockedPeriodAmount = _lockedPeriodAmount;
        devAddress = _devAddress;
    }

    /* ========== VIEWS ========== */

    function getVestingAmount()
        external
        view
        override
        returns (uint256 lockedAmount, uint256 claimableAmount)
    {
        LockedReward memory lockedRewards = userLockedRewards[msg.sender];
        uint256 totalLockedPeriod = period * lockedPeriodAmount;
        if (block.timestamp < lockedRewards.start + totalLockedPeriod) {
            
          uint256 diff = (block.timestamp - lockedRewards.lastClaimed) / period * period;
          claimableAmount = lockedRewards.vesting * diff / totalLockedPeriod;
          if (claimableAmount > totalLockedRewards) {
              claimableAmount = totalLockedRewards;
          }
        } else {
          claimableAmount = lockedRewards.pending;
        }
        lockedAmount = lockedRewards.pending - claimableAmount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claim() external override {
        _claim(msg.sender);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function lock(address account, uint256 amount) public override onlyFarms {
        _claim(account);
        LockedReward memory oldLockedRewards = userLockedRewards[account];
        oldLockedRewards.pending += amount;
        uint256 startTimestamp = block.timestamp / period * period + period;

        userLockedRewards[account] = LockedReward({
            pending: oldLockedRewards.pending,
            vesting: oldLockedRewards.pending,
            start: startTimestamp,
            lastClaimed: block.timestamp
        });

        totalLockedRewards = totalLockedRewards + amount;
        emit Lock(account, amount);
    }

    function addFarm(address _farmAddress) 
        external 
        override 
        onlyGovernance 
    {   
        require(_farmAddress != address(0), "VestingMaster::set: Zero address");
        farms[_farmAddress] = true;
        emit AddFarm(msg.sender, _farmAddress);
    }

    function removeFarm(address _farmAddress) 
        external 
        override 
        onlyGovernance 
    {   
        farms[_farmAddress] = false;
        emit RemoveFarm(msg.sender, _farmAddress);
    }

    function setDevAddress(address _devAddress)
        external 
        override
        onlyGovernance
    {
        require(_devAddress != address(0), "VestingMaster::set: Zero address");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _claim(address account) internal {
        LockedReward storage lockedRewards = userLockedRewards[account];   
        uint256 claimableAmount;
        uint256 totalLockedPeriod = period * lockedPeriodAmount;
        if (block.timestamp < lockedRewards.start + totalLockedPeriod) {
            uint256 diff = (block.timestamp - lockedRewards.lastClaimed) / period * period;
            claimableAmount = lockedRewards.vesting * diff / totalLockedPeriod;
        } else {
            claimableAmount = lockedRewards.pending;
        }

        if (claimableAmount > totalLockedRewards) {
            claimableAmount = totalLockedRewards;
        }
        lockedRewards.lastClaimed = block.timestamp;
        lockedRewards.pending = lockedRewards.pending - claimableAmount;
        totalLockedRewards = totalLockedRewards - claimableAmount;
        vestingToken.safeTransfer(account, claimableAmount);

        emit Claim(account, claimableAmount);
    }
}