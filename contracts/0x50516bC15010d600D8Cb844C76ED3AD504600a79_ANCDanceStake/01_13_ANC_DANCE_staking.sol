// SPDX-License-Identifier: MIT
/***
 *                                                                 .';:c:,.
 *                   ;0NNNNNNX.  lNNNNNNK;       .XNNNNN.     .:d0XWWWWWWWWXOo'
 *                 lXWWWWWWWWO   XWWWWWWWWO.     :WWWWWK    ;0WWWWWWWWWWWWWWWWWK,
 *              .dNWWWWWWWWWWc  ,WWWWWWWWWWNo    kWWWWWo  .0WWWWWNkc,...;oXWWXxc.
 *            ,kWWWWWWXWWWWWW.  dWWWWWXNWWWWWX; .NWWWWW.  KWWWWW0.         ;.
 *          :KWWWWWNd.lWWWWWO   XWWWWW:.xWWWWWWOdWWWWW0  cWWWWWW.
 *        lXWWWWWXl.  0WWWWW:  ,WWWWWN   '0WWWWWWWWWWWl  oWWWWWW;         :,
 *     .dNWWWWW0;    'WWWWWN.  xWWWWWx     :XWWWWWWWWW.  .NWWWWWWkc,'';ckNWWNOc.
 *   'kWWWWWWx'      oWWWWWk   NWWWWW,       oWWWWWWW0    '0WWWWWWWWWWWWWWWWWO;
 * .d000000o.        k00000;  ,00000k         .x00000:      .lkKNWWWWWWNKko;.
 *                                                               .,;;'.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ANCStake.sol";
import "./IERC20F.sol";

contract ANCDanceStake is ANCStake{
    struct StakedDance {
        uint128 stakingStartWeek;
        uint32 coins;
        uint32 stakingDuration;
        uint32 paidDuration;
    }

    uint96 public immutable TOKENS_PER_COIN = 1e18; // 1 full coin = 10^18

    IERC20F private _dance;

    mapping(address => StakedDance[]) private _stakes;

    constructor(uint256 percentPerWeek) ANCStake(percentPerWeek){ }

    /* External Functions */

    function stake(uint32 coins, uint16 stakingDuration) external stakingGate(stakingDuration){
        require(coins > 0, "Need to stake at least 1 DANCE");
        uint256 amount = uint256(coins) * TOKENS_PER_COIN;
        uint256 allowance = _dance.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        uint256 currentWeek = getCurrentWeek();
        _dance.transferFromNoFee(msg.sender, address(this), amount);
        _stakes[msg.sender].push(StakedDance(uint128(currentWeek), coins, stakingDuration, 0));
        addSharesToWeeks(currentWeek, stakingDuration, getShares(coins, stakingDuration));
    }

    function unstake(uint256 id) external {
        require(_stakes[msg.sender].length > id, "Invalid ID");
        uint256 refund = _stakes[msg.sender][id].coins * TOKENS_PER_COIN;
        uint256 payout = _unstakeDance(id);
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
        _dance.transferNoFee(msg.sender, refund);
    }

    function unstakeAll() external {
        require(_stakes[msg.sender].length > 0, "No Dance Tokens staked");
        uint256 currentWeek = getCurrentWeek();
        uint256 payout = 0;
        uint256 refund = 0;

        // While required since array length changes in _unstakeDance
        uint256 i = 0;
        while (i < _stakes[msg.sender].length) {
            uint256 stakingStartWeek = _stakes[msg.sender][i].stakingStartWeek;
            if(currentWeek - stakingStartWeek >= _stakes[msg.sender][i].stakingDuration){
                refund += _stakes[msg.sender][i].coins * TOKENS_PER_COIN;
                payout += _unstakeDance(i);
            } else {
                i += 1;
            }
        }
        // require here so pre-computation will save you.
        require(payout > 0, "No staking period over");
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
        _dance.transferNoFee(msg.sender, refund);
    }

    function payoutReward(uint256 id) external override {
        require(_stakes[msg.sender].length > id, "Invalid ID");
        StakedDance memory mstake = _stakes[msg.sender][id];
        uint256 currentWeek = getCurrentWeek();
        require(currentWeek - mstake.stakingStartWeek < mstake.stakingDuration, "Staking period is over, use unstake function instead");
        require(mstake.stakingStartWeek + mstake.paidDuration < currentWeek, "Nothing to pay out");
        reserveForPastWeeks(currentWeek);
        uint256 payout = _getReward(currentWeek, mstake);
        _stakes[msg.sender][id].paidDuration = uint16(min(currentWeek - mstake.stakingStartWeek, mstake.stakingDuration));
        require(payout > 0, "No reward to pay out");
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function payoutAllRewards() external {
        StakedDance[] memory mstakes= _stakes[msg.sender];
        require(mstakes.length > 0, "No Dance Tokens staked");
        uint256 currentWeek = getCurrentWeek();
        reserveForPastWeeks(currentWeek);
        uint256 payout = 0;
        uint256 stakingStartWeek;
        uint256 duration;
        uint256 paidDuration;
        for (uint256 id = 0; id < mstakes.length; id++) {
            stakingStartWeek = mstakes[id].stakingStartWeek;
            duration = mstakes[id].stakingDuration;
            paidDuration = mstakes[id].paidDuration;
            if (currentWeek - stakingStartWeek < duration
                && stakingStartWeek + paidDuration < currentWeek){
                payout += _getReward(currentWeek, mstakes[id]);
                _stakes[msg.sender][id].paidDuration = uint16(min(currentWeek - stakingStartWeek, duration));
            }
        }
        // require here so pre-computation will save you.
        require(payout > 0, "No reward to pay out");
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function setRewardToken(address tokenAddress) external onlyOwner {
        require(_dance == IERC20F(address(0)), "dance token is already set");
        require(tokenAddress != address(0), "dance token cannot be 0 address");
        _dance = IERC20F(tokenAddress);
    }

    /* Public Functions */

    function getNumStaked(address address_) public view override returns(uint256){
        return _stakes[address_].length;
    }

    function getStakeInfo(address address_, uint256 id_) public view returns(StakedDance memory){
        return _stakes[address_][id_];
    }

    function getAvailablePayout(address address_, uint256 id_) public view returns(uint256){
        uint256 currentWeek = getCurrentWeek();
        StakedDance memory mstake = _stakes[address_][id_];
        uint256 endWeek = mstake.stakingStartWeek + mstake.stakingDuration;
        uint256 startWeek = mstake.stakingStartWeek + mstake.paidDuration;
        uint256 shares = getShares(mstake.coins, mstake.stakingDuration);
        return _getAvailablePayout(startWeek, endWeek, currentWeek, shares);
    }

    function getStakedIDs(address address_) public view override returns(uint256[] memory){
        uint256 numStaked = getNumStaked(address_);
        uint256[] memory stakedIDs = new uint256[](numStaked);
        for (uint256 id = 0; id < numStaked; id++) {
            stakedIDs[id] = id;
        }
        return stakedIDs;
    }

    function getShares(uint32 coins, uint32 stakingDuration) public pure returns(uint256){
        // max shares per coin < (2^32 -1)/21000000 = 204
        uint256 sD = stakingDuration;
        uint256 base = 50;
        uint256 linear = 30 * sD / MAX_STAKING_DURATION;
        uint256 quadratic = 20 * sD * sD / (MAX_STAKING_DURATION*MAX_STAKING_DURATION);
        return coins * (base + linear + quadratic);
    }

    /* Internal Functions */

    function _unstakeDance(uint256 id) internal returns(uint256) {
        StakedDance memory mstake = _stakes[msg.sender][id];
        uint256 currentWeek = getCurrentWeek();
        require(currentWeek - mstake.stakingStartWeek >= mstake.stakingDuration, "Staking period not over");
        reserveForPastWeeks(currentWeek); // reserve reward tokens
        uint256 payout = _getReward(currentWeek, mstake);
        _stakes[msg.sender][id] = _stakes[msg.sender][_stakes[msg.sender].length - 1];
        _stakes[msg.sender].pop();
        return payout;
    }

    function _getReward(uint256 currentWeek, StakedDance memory mstake) internal view returns(uint256){
        require(mstake.stakingStartWeek > 0, "ID is not staked");
        uint256 payout = getStakingReward(
            mstake.stakingStartWeek,
            currentWeek,
            mstake.stakingDuration,
            mstake.paidDuration,
            getShares(mstake.coins, uint16(mstake.stakingDuration))
        );
        // need to update state (paidDuration) in next step
        return payout;
    }

}