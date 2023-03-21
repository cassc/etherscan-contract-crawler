// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SafeCast.sol';
import '../@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '../@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './../PoolStakingRewards/PoolStakingRewards4.sol';
import './../PoolCore/Pool13.sol';

// import "hardhat/console.sol";

contract HomeBoost0 is
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC721Upgradeable
{
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint16;
    // 60 * 60 * 24
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant SECONDS_PER_WEEK = SECONDS_PER_DAY * 7;
    // use mortgage year (360 days)
    uint256 constant SECONDS_PER_YEAR = SECONDS_PER_DAY * 360;
    // 90 days
    uint256 constant LEVEL_1_SECONDS_PER_ITERATION = SECONDS_PER_DAY * 90;
    // 1 year
    uint256 constant LEVEL_2_SECONDS_PER_ITERATION = SECONDS_PER_DAY * 360;

    // Stored per boost token.
    struct Boost {
        uint64 startTime;
        uint64 principal;
        uint64 claimedRewards;
        uint64 additionalMatureSeconds; // accumulates seconds that the Boost was mature before being renewed.
        uint16 endIteration; // 0 for never (auto-renew) or a value for the number of iterations
        uint16 level;
    }

    // Used to get relevant details about boosts to callers into the contract (e.g. the UI)
    // Never written to storage.
    struct BoostDetail {
        uint256 id;
        uint256 startTime;
        uint256 principal;
        uint256 claimedRewards;
        uint256 totalRewards;
        uint256 apy;
        uint256 nextRewardTimestamp;
        uint16 level;
        bool isComplete; // true if time has passed the end of the last iteration
        bool isAutoRenew;
    }

    Boost[] private boostData;
    uint256 weeklyStartTime;
    uint256[] private weeklyInterestRates;

    address poolAddress;
    address guardianAddress;
    address poolStakingRewardAddress;
    mapping(address => bool) isApproved;
    string boostBaseURI;

    function initialize(string memory name, string memory symbol, address _guardianAddress, address _poolAddress, address _poolStakingRewardAddress) public initializer {
        // TODO: needed since we are already storing the pool address? 
        isApproved[_poolAddress] = true;
        poolAddress = _poolAddress;
        guardianAddress = _guardianAddress;
        poolStakingRewardAddress = _poolStakingRewardAddress;

        ERC721Upgradeable.__ERC721_init(name, symbol);

        // Push a null Boost into the list of boosts to act as a sentinel. This way anyone that points to boost id 0
        // will get the sentinel rather than the first boost created for a real user. Make sure to only do this once
        if (boostData.length == 0) {
            boostData.push(Boost(0, 0, 0, 0, 0, 0));
        }
    }

    ///
    /// Getters
    ///
    function _baseURI() internal view override returns (string memory) {
        return boostBaseURI;
    }

    //
    // returns startTime, principal, additionalMatureSeconds, endIteration, level
    // use getTokenData for a more human readable version of this data
    //
    function getRawTokenData(uint256 tokenId) public view returns(Boost memory) {
        return boostData[tokenId];
    }

    function getPerIterationRateForLevel(uint16 level, uint64 startTime, uint256 endTime) private view returns(uint256) {
        if (level == 1) {
            return 5000;
        } else if (level == 2) {
            return getPerIterationRateForLevel2(startTime, endTime);
        }

        return 0;
    }

    function getPerIterationRateForLevel2(uint64 startTime, uint256 endTime) public view returns(uint256) {
        if (weeklyInterestRates.length == 0 || startTime == endTime)
            return 0;

        require(startTime >= weeklyStartTime, "startTime must be greater because negatives are bad");
        uint256 startWeekNumber = (startTime - weeklyStartTime) / SECONDS_PER_WEEK;
        uint256 startWeekFraction =  ((startTime - weeklyStartTime) % SECONDS_PER_WEEK);

        // We're at the start, so we need the time elaspsed since the start to a week ending.
        // Mod takes it to zero if startWeekFraction is already zero. Might be better to if it.
        startWeekFraction = (SECONDS_PER_WEEK - startWeekFraction) % SECONDS_PER_WEEK;

        uint256 endWeekNumber = ((endTime - weeklyStartTime) / SECONDS_PER_WEEK);
        uint256 endWeekNumberFraction = ((endTime - weeklyStartTime) % SECONDS_PER_WEEK);
        require(endWeekNumber < weeklyInterestRates.length, "Weekly rate not set yet");

        // fracitonalSum isn't a uint. It's really interest seconds, but that's not a type here.
        uint256 fracitonalSum = (weeklyInterestRates[endWeekNumber] * endWeekNumberFraction);

        // We're still in the first week. All the other stuff is unnecessary.
        // And breaks if we don't exit early.
        if (endWeekNumber - startWeekNumber == 0)
           return fracitonalSum / (endTime - startTime);

        fracitonalSum += (weeklyInterestRates[startWeekNumber] * startWeekFraction);

        // The first week is handled in the loop, if there's no fractional part.
        if (startWeekFraction > 0)
          startWeekNumber += 1;

        // sum is actually interest weeks.
        uint256 sum = 0;
        uint256 i;

        for (i = startWeekNumber; i < endWeekNumber; i++) {
          sum += weeklyInterestRates[i];
        }

        // Normalize the return to interest/timespan.
        sum = ((sum * SECONDS_PER_WEEK) + fracitonalSum) / (endTime - startTime);
        return sum;
    }

    function getAPYForLevel(uint16 level) public view returns(uint256) {
        if (level == 1) {
            return 20000;
        } else if (level == 2) {
            if (weeklyInterestRates.length == 0)
              return 0;
            return weeklyInterestRates[weeklyInterestRates.length - 1];
        }
        return 0;
    }

    //
    // Returns the amount of token that is sent to staking to earn BACON rewards
    //
    function getStakeAmount(uint16 level, uint256 rawAmount) public pure returns(uint256) {
        if (level == 1) {
            return rawAmount.div(2); // 50% of the rewards
        } else if (level == 2) {
            return rawAmount;        // 100% of the rewards
        }
        return 0;
    }


    function getSecondsPerIteration(uint16 level) private pure returns(uint256) {
        if (level == 1) {
            return LEVEL_1_SECONDS_PER_ITERATION;
        } else if (level == 2) {
            return LEVEL_2_SECONDS_PER_ITERATION;
        }
        return 0;
    }

    function getNextRewardTimestamp(Boost memory boost) private view returns(uint256) {
        if (boost.endIteration == 0) {
            uint256 nextIteration = (block.timestamp - boost.startTime).div(getSecondsPerIteration(boost.level)) + 1;
            return boost.startTime + getSecondsPerIteration(boost.level).mul(nextIteration);
        } else {
            return boost.startTime + getSecondsPerIteration(boost.level).mul(boost.endIteration);
        }
    }

    //
    // Returns a list of token data structures, one for each token owned by the caller.
    //
    function getTokens() public view returns(BoostDetail[] memory)
    {
        uint256 ownedTokens = balanceOf(msg.sender);
        BoostDetail[] memory details = new BoostDetail[](ownedTokens);
        if (ownedTokens == 0) {
            return details;
        }
        uint256 currentDetailIndex = 0;
        // Index 0 is a placeholder so skip it.
        for(uint256 currentId = 1; currentId < boostData.length; currentId++) {
            if (!_exists(currentId) || ownerOf(currentId) != msg.sender){
                continue;
            }

            if (currentDetailIndex == details.length){
                break;
            }

            Boost storage currentBoost = boostData[currentId];
            uint256 nextRewardTimestamp = getNextRewardTimestamp(currentBoost);
            details[currentDetailIndex] = BoostDetail(
                currentId,
                currentBoost.startTime,
                currentBoost.principal,
                currentBoost.claimedRewards,
                computeTotalRewards(currentBoost, nextRewardTimestamp),
                getAPYForLevel(currentBoost.level),
                nextRewardTimestamp,
                currentBoost.level,
                nextRewardTimestamp < block.timestamp,
                currentBoost.endIteration == 0
            );

            currentDetailIndex++;
        }

        return details;
    }


    ///
    /// Mutations
    ///

    function approveAccess(address addr) public{
        require(msg.sender == guardianAddress, "caller must be guardian");
        isApproved[addr] = true;
    }

    function revokeAccess(address addr) public{
        require(msg.sender == guardianAddress, "caller must be guardian");
        isApproved[addr] = false;
    }

    function setBoostBaseUri(string memory _boostBaseURI) public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        boostBaseURI = _boostBaseURI;
    }

    function pause() public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        _pause();
    }

    function unpause() public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        _unpause();
    }

    // Create a boost token
    function mint(address to, uint256 principal, uint16 level, bool autoRenew) public whenNotPaused nonReentrant returns (bool) {
        require(isApproved[msg.sender], "Caller must be approved");

        uint16 endIteration = autoRenew ? 0 : 1;

        boostData.push(Boost(SafeCast.toUint64(block.timestamp), SafeCast.toUint64(principal), 0, 0, endIteration, level));
        uint256 tokenId = boostData.length - 1;

        _safeMint(to, tokenId);
        
        return true;
    }

    function beforeIterationChange(Boost storage boost) private {
        if (getNextRewardTimestamp(boost) < block.timestamp) {
            // Boost is mature so we have to record the number of days that it was mature so we can pay interest on them
            uint256 boostedDuration = getSecondsPerIteration(boost.level).mul(boost.endIteration);
            boost.additionalMatureSeconds += SafeCast.toUint64(block.timestamp - (boost.startTime + boostedDuration));
            boost.startTime = SafeCast.toUint64(block.timestamp - boostedDuration);
        }
    }

    // Set a boost to auto renew.
    // if boost is already auto renew do nothing
    // if boost is not yet mature, just set the iteration count to 0
    // else boost is mature, stash the additionalMatureSeconds, set startTime to currentBlockTime - iterationCount*iterationDuration and set iterationCount to 0
    function setToAutoRenew(uint256 boostId) public whenNotPaused{
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        if (boost.endIteration == 0) {
            return;
        }

        beforeIterationChange(boost);

        boost.endIteration = 0;
    }

    // End the auto renew on a boost. This will allow it to be claimed when the current iteration is over.
    function endAutoRenew(uint256 boostId) public whenNotPaused {
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        if (boost.endIteration != 0) {
            return;
        }

        boost.endIteration = (uint16) ((block.timestamp - boost.startTime).div(getSecondsPerIteration(boost.level)) + 1);
    }

    // claim the rewards and principal from a boost. This also burns the boost token.
    function claimPrincipal(uint256 boostId) public whenNotPaused nonReentrant returns (uint256) {
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        // endAutoRenew must be called first
        require(boost.endIteration != 0, "Must not be autoRenew");
        // boost must be mature
        uint256 nextRewardTimestamp = getNextRewardTimestamp(boost);
        require(nextRewardTimestamp < block.timestamp, "Still locked");

        uint256 claimedRewards = claimRewardsCore(boost, nextRewardTimestamp);

        _burn(boostId);
        // Portions of the Principal is held by the staking contract so that it can earn bacon.
        uint256 amountStaked = getStakeAmount(boost.level, boost.principal);
        PoolStakingRewards4(poolStakingRewardAddress).unstakeForWallet(msg.sender, amountStaked);

        if (amountStaked < boost.principal) {
            // Return the non-staked boost principal held in this contract
            IERC20(poolAddress).transfer(msg.sender, boost.principal - amountStaked);
        }

        return boost.principal + claimedRewards;
    }

    // Allow users to unstake all HOME staked using the old staking methods.
    function claimPreBoostStake() public whenNotPaused nonReentrant returns (uint256) {
        uint256 ownedTokenCount = balanceOf(msg.sender);
        uint256 stakedAmount = PoolStakingRewards4(poolStakingRewardAddress).getCurrentBalance(msg.sender);

        uint boostStakedAmount = 0;
        if (ownedTokenCount > 0) {
            // compute the total amount staked by boosts. This is going to grow in cost as the total number of boosts
            // grows, but the common case should be calling this once when the caller has 0 boosts.
            uint256 currentOwnedIndex = 0;
            // Index 0 is a placeholder so skip it.
            for(uint256 currentId = 1; currentId < boostData.length; currentId++) {
                if (!_exists(currentId) || ownerOf(currentId) != msg.sender){
                    continue;
                }

                if (currentOwnedIndex == ownedTokenCount){
                    break;
                }

                Boost storage boost = boostData[currentId];
                boostStakedAmount = boostStakedAmount.add(getStakeAmount(boost.level, boost.principal));

                currentOwnedIndex++;
            }
        }

        //
        uint256 amount = stakedAmount.sub(boostStakedAmount);

        PoolStakingRewards4(poolStakingRewardAddress).unstakeForWallet(msg.sender, amount);

        return amount;
    }

    // Claim all the rewards that can be claimed from this boost. This is only what is earned from past iterations.
    function claimRewards(uint256 boostId) public whenNotPaused nonReentrant returns (uint256) {
        // Claim only the rewards that have been earned so far in this boost - the rewards that have already been claimed
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        uint256 nextRewardTimestamp = getNextRewardTimestamp(boost);

        return claimRewardsCore(boost, nextRewardTimestamp);
    }

    function computeTotalRewards(Boost storage boost, uint256 nextRewardTimestamp) private view returns (uint256) {
        uint256 totalRewardAmount;
        uint256 newMatureSeconds = 0;
        // if the boost is mature, then just udpate how long we've been mature and pay those rewards
        if (nextRewardTimestamp < block.timestamp) {
            newMatureSeconds = block.timestamp - nextRewardTimestamp;
            totalRewardAmount = boost.principal.mul(boost.endIteration).mul(getPerIterationRateForLevel(boost.level, boost.startTime, nextRewardTimestamp)).div(1000000);
        } else {
            // Otherwise the boost isn't mature. We can pay rewards up to the last full iteration
            uint256 completeIterations = (block.timestamp - boost.startTime).div(getSecondsPerIteration(boost.level));
            totalRewardAmount = boost.principal.mul(completeIterations).mul(getPerIterationRateForLevel(boost.level, boost.startTime, block.timestamp)).div(1000000);
        }
        totalRewardAmount += boost.principal.mul(boost.additionalMatureSeconds + newMatureSeconds).div(SECONDS_PER_YEAR).div(100);
        return totalRewardAmount;
    }

    function claimRewardsCore(Boost storage boost, uint256 nextRewardTimestamp) private returns (uint256) {
        uint256 totalRewardAmount = computeTotalRewards(boost, nextRewardTimestamp);
        // subtract out the rewards that we have already paid
        uint256 rewardAmount = totalRewardAmount.sub(boost.claimedRewards);
        boost.claimedRewards = SafeCast.toUint64(totalRewardAmount);

        // pay the rewards if there are any
        if (rewardAmount > 0) {
            Pool13(poolAddress).transferBoostRewards(msg.sender, rewardAmount);
        }

        return rewardAmount;
    }

    function appendInterestRate(uint256 newRate) public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        weeklyInterestRates.push(newRate);
    }

    function setWeeklyStartTime(uint256 _weeklyStartTime) public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        weeklyStartTime = _weeklyStartTime;
    }
}