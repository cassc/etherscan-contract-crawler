// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Ownable.sol";
import "ERC20Burnable.sol";
contract Staking is Ownable {
    address public stakeToken;
    address public treasure;

    uint public unHoldFee;
    uint public minStakeAmount;
    uint public zeroRewardTimePercent;
    bool public paused=true;

    struct StakeData {
        uint stakeAmount;
        uint startTimestamp;
        uint stakeTime;
        bool active;
    }

    mapping(address => StakeData) public stakes;

    event Stake(address indexed staker, uint stakeAmountIn, uint stakeTime);
    event Withdraw(address indexed staker, uint stakeAmountOut);

    // stakeTime => reward in %, 100e18 is 100%
    mapping (uint => uint) public timeReward;

    constructor(address stakeToken_, address treasure_, uint zeroRewardTimePercent_, uint minStakeAmount_) {
        require(
            stakeToken_ != address(0)
            && treasure_ != address(0),
            "Staking::initialize: address is 0"
        );

        stakeToken = stakeToken_;
        treasure = treasure_;

        minStakeAmount = minStakeAmount_;
        unHoldFee = 30e18; // 30%
        zeroRewardTimePercent = zeroRewardTimePercent_;
        timeReward[90 days]  = 20e18; // 20%
        timeReward[180 days] = 40e18; // 40%
        timeReward[360 days] = 60e18; // 60%
        timeReward[720 days] = 60e18; // 60%
    }

    function updateZeroRewardTimePercent(uint _newPercent) public onlyOwner returns (bool) {
        zeroRewardTimePercent = _newPercent;
        return true;
    }
    function updateTimeReward(uint stakeTime, uint percentReward) public onlyOwner returns (bool) {
        timeReward[stakeTime] = percentReward;

        return true;
    }

    function setTreasure(address treasure_) public onlyOwner returns (bool) {
        treasure = treasure_;

        return true;
    }

    function setPause(bool paused_) public onlyOwner returns (bool) {
        paused = paused_;

        return true;
    }

    function updateMinStakeAmount(uint amount_) public onlyOwner returns (bool) {
        minStakeAmount = amount_;

        return true;
    }

    // transfer stake tokens from user to pool
    function stake(uint tokenAmount, uint stakeTime) public returns (bool) {
        require(!paused, "Staking::stake: stake is paused");

        uint rewardPercent = timeReward[stakeTime];
        require(rewardPercent != 0, "Staking::stake:rewardPercent must be more than 0");

        address staker = msg.sender;
        require(!stakes[staker].active, "Staking::stake:stake must be not active");

        stakes[staker].active = true;
        uint amountIn = doTransferIn(staker, stakeToken, tokenAmount);
        require(amountIn > minStakeAmount, "Staking::stake: stake amount must be more than minStakeAmount");

        uint timestamp = getBlockTimestamp();
        stakes[staker].startTimestamp = timestamp;
        stakes[staker].stakeTime = stakeTime;
        stakes[staker].stakeAmount = amountIn;

        emit Stake(staker, amountIn, stakeTime);

        return true;
    }

    // transfer stake tokens from pool to user
    function withdraw() external {
        address staker = msg.sender;
        require(stakes[staker].active, "Staking::withdraw: stake must be active");
        stakes[staker].active = false;

        (uint amountOut, uint feeAmount) = calcOutAmount(staker);
        if (feeAmount > 0) {
            uint transferOutAmount = feeAmount / 2;

            ERC20Burnable(stakeToken).burn(transferOutAmount);
            ERC20Burnable(stakeToken).transfer(treasure, transferOutAmount);
        } 
        doTransferOut(stakeToken, staker, amountOut);

        emit Withdraw(staker, amountOut);
    }

    function calcFee(uint stakeAmount, uint currentTimestamp, uint startTimestamp, uint stakeTime) public view returns (uint) {
        uint delta = (currentTimestamp - startTimestamp);
        if (stakeTime <= delta) {
            return 0;
        }

        return stakeAmount * unHoldFee * (stakeTime - delta) / stakeTime / 100e18;
    }

    function getStake(address user) public view returns (StakeData memory) {
        return stakes[user];
    }

    function calcOutAmount(address staker) public view returns (uint, uint) {
        uint stakeAmount = stakes[staker].stakeAmount;
        uint startTimestamp = stakes[staker].startTimestamp;
        uint stakeTime = stakes[staker].stakeTime;
        uint currentTimestamp = getBlockTimestamp();

        uint feeAmount = calcFee(stakeAmount, currentTimestamp, startTimestamp, stakeTime);
        uint amountOut;

        if (feeAmount > 0) {
            amountOut = stakeAmount - feeAmount;
         }
        else {
            uint endZeroRewardPeriod = (startTimestamp + stakeTime) + stakeTime * zeroRewardTimePercent / 100;
            if(currentTimestamp <= endZeroRewardPeriod) {
                amountOut = stakeAmount;
            }
            else {
                amountOut = stakeAmount + (stakeAmount * timeReward[stakeTime] / 100e18);
            }
        }    
        return(amountOut, feeAmount);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockTimestamp() internal virtual view returns (uint) {
        return block.timestamp;
    }

    function doTransferIn(address from, address token, uint amount) internal returns (uint) {
        uint balanceBefore = ERC20(token).balanceOf(address(this));
        ERC20(token).transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {                       // This is a non-standard ERC-20
                success := not(0)          // set success to true
            }
            case 32 {                      // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0)        // Set `success = returndata` of external call
            }
            default {                      // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = ERC20(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    function doTransferOut(address token, address to, uint amount) internal {
        ERC20(token).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {                      // This is a non-standard ERC-20
                success := not(0)          // set success to true
            }
            case 32 {                     // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0)        // Set `success = returndata` of external call
            }
            default {                     // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}