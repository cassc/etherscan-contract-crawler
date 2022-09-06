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

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "./ANCStake.sol";

contract ANCApeStake is ANCStake {
    struct StakedApe {
        uint128 stakingStartWeek;
        uint32 stakingDuration;
        uint32 paidDuration;
    }

    IERC721A private _ancApe;

    mapping(address => mapping(uint256 => StakedApe)) private _stakes;

    constructor(uint256 percentPerWeek, address nftTokenAddress) ANCStake(percentPerWeek){
        _ancApe = IERC721A(nftTokenAddress);
    }

    /* External Functions */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function stake(uint256 tokenId, uint32 stakingDuration) external stakingGate(stakingDuration){
        _ancApe.safeTransferFrom(msg.sender, address(this), tokenId);
        uint256 currentWeek = getCurrentWeek();
        _stakes[msg.sender][tokenId] = StakedApe(uint128(currentWeek), stakingDuration, 0);
        addSharesToWeeks(currentWeek, stakingDuration, getShares(stakingDuration));
    }

    function multiStake(uint256[] calldata tokenIDs, uint32 stakingDuration) external stakingGate(stakingDuration){
        require(tokenIDs.length>0, "No token IDs given");
        require(tokenIDs.length<=20, "Can't stake more than 20 at once"); //to prevent excessive gas use
        uint256 currentWeek = getCurrentWeek();
        uint256 tokenId;
        for (uint256 id = 0; id < tokenIDs.length; id++) {
            tokenId = tokenIDs[id];
            _ancApe.safeTransferFrom(msg.sender, address(this), tokenId);
            _stakes[msg.sender][tokenId] = StakedApe(uint128(currentWeek), stakingDuration, 0);
        }
        addSharesToWeeks(currentWeek, stakingDuration, getShares(stakingDuration)*tokenIDs.length);
    }

    function unstake(uint256 _tokenId) external {
        uint256 currentWeek = getCurrentWeek();
        reserveForPastWeeks(currentWeek); // reserve reward tokens
        StakedApe memory mstake = _stakes[msg.sender][_tokenId];
        require(currentWeek - mstake.stakingStartWeek >= mstake.stakingDuration, "Staking period not over");
        uint256 payout = _getReward(currentWeek, mstake);
        _reservedTokens -= payout; // remove payout tokens from reserved
        delete _stakes[msg.sender][_tokenId];

        _ancApe.safeTransferFrom(address(this), msg.sender, _tokenId);
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function multiUnstake(uint256[] calldata tokenIDs) external {
        require(tokenIDs.length>0, "No token IDs given");
        require(tokenIDs.length<=20, "Can't unstake more than 20 at once"); //to prevent excessive gas use
        uint256 currentWeek = getCurrentWeek();
        reserveForPastWeeks(currentWeek); // reserve reward tokens
        uint256 payout = 0;
        uint256 tokenId;
        StakedApe memory mstake;
        for (uint256 id = 0; id < tokenIDs.length; id++) {
            tokenId = tokenIDs[id];
            mstake = _stakes[msg.sender][tokenId];
            require(currentWeek - mstake.stakingStartWeek >= mstake.stakingDuration, "Staking period not over");
            payout += _getReward(currentWeek, mstake);
            delete _stakes[msg.sender][tokenId];
            _ancApe.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        _reservedTokens -= payout; // remove payout tokens from reserved
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function payoutReward(uint256 _tokenId) external override {
        uint256 currentWeek = getCurrentWeek();
        reserveForPastWeeks(currentWeek); // reserve reward tokens
        StakedApe memory mstake = _stakes[msg.sender][_tokenId];
        require(currentWeek - mstake.stakingStartWeek < mstake.stakingDuration, "Staking period is over, use unstake function instead");
        require(mstake.stakingStartWeek + mstake.paidDuration < currentWeek, "Nothing to pay out");
        uint256 payout = _getReward(currentWeek, mstake);
        _reservedTokens -= payout;
        _stakes[msg.sender][_tokenId].paidDuration = uint16(min(currentWeek - mstake.stakingStartWeek, mstake.stakingDuration));
        require(payout > 0, "No reward to pay out");
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function multiPayoutRewards(uint256[] calldata tokenIDs) external {
        uint256 currentWeek = getCurrentWeek();
        reserveForPastWeeks(currentWeek); // reserve reward tokens
        uint256 payout = 0;
        uint256 tokenId;
        StakedApe memory mstake;
        for (uint256 id = 0; id < tokenIDs.length; id++) {
            tokenId = tokenIDs[id];
            mstake = _stakes[msg.sender][tokenId];
            if(!canBeUnstaked(mstake, currentWeek)) {
                //require(currentWeek - mstake.stakingStartWeek < mstake.stakingDuration, "Staking period is over, use unstake function");
                if(mstake.stakingStartWeek + mstake.paidDuration < currentWeek){
                    payout += _getReward(currentWeek, mstake);
                    _stakes[msg.sender][tokenId].paidDuration = uint16(min(currentWeek - mstake.stakingStartWeek, mstake.stakingDuration));
                }
            }
        }
        _reservedTokens -= payout;
        require(payout > 0, "No reward to pay out");
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function getIDsDoneStaking(address address_) external view returns(uint256[] memory){
        uint256 currentWeek = getCurrentWeek();
        uint256 numDoneStaking = 0;
        uint256[] memory stakedIDs = getStakedIDs(address_);
        uint256 tokenId;
        // calculate how many token IDs are ready to be unstaked
        for (uint256 i = 0; i < stakedIDs.length; i++) {
            tokenId = stakedIDs[i];
            if (canBeUnstaked(_stakes[address_][tokenId], currentWeek)) numDoneStaking += 1;
        }
        // select token IDs ready for unstaking
        uint256[] memory doneStaking = new uint256[](numDoneStaking);
        uint256 index = 0;
        for (uint256 i = 0; i < stakedIDs.length; i++) {
            tokenId = stakedIDs[i];
            if (canBeUnstaked(_stakes[address_][tokenId], currentWeek)) {
                doneStaking[index] = tokenId;
                index += 1;
            }
        }
        return doneStaking;
    }

    /* Public Functions */

    function getNumStaked(address address_) public view override returns(uint256){
        uint256 supply = _ancApe.totalSupply();
        uint256 numStaked = 0;
        for (uint256 id = 0; id < supply; id++) {
            if(_stakes[address_][id].stakingStartWeek > 0){
                numStaked += 1;
            }
        }
        return numStaked;
    }

    function getStakeInfo(address address_, uint256 tokenId_) public view returns(StakedApe memory){
        return _stakes[address_][tokenId_];
    }

    function getAvailablePayout(address address_, uint256 tokenId_) public view returns(uint256){
        uint256 currentWeek = getCurrentWeek();
        StakedApe memory mstake = _stakes[address_][tokenId_];
        uint256 endWeek = mstake.stakingStartWeek + mstake.stakingDuration;
        uint256 startWeek = mstake.stakingStartWeek + mstake.paidDuration;
        uint256 shares = getShares(mstake.stakingDuration);
        return _getAvailablePayout(startWeek, endWeek, currentWeek, shares);
    }

    function getStakedIDs(address address_) public view override returns(uint256[] memory){
        uint256 supply = _ancApe.totalSupply();
        uint256 numStaked = getNumStaked(address_);
        uint256[] memory stakedIDs = new uint256[](numStaked);
        uint256 index = 0;
        for (uint256 id = 0; id < supply; id++) {
            if(_stakes[address_][id].stakingStartWeek > 0){
                stakedIDs[index] = id;
                index += 1;
            }
        }
        return stakedIDs;
    }

    function getShares(uint32 stakingDuration) public pure returns(uint256){
        // max shares per nft < (2^32 -1)/8888 = 483232
        uint256 sD = stakingDuration;
        uint256 base = 50;
        uint256 linear = 30 * sD / MAX_STAKING_DURATION;
        uint256 quadratic = 20 * sD * sD / (MAX_STAKING_DURATION*MAX_STAKING_DURATION);
        return base + linear + quadratic;
    }

    /* Internal Functions */

    function _getReward(uint256 currentWeek, StakedApe memory mstake) internal view returns(uint256){
        require(mstake.stakingStartWeek > 0, "Token is not staked");
        uint256 payout = getStakingReward(
            mstake.stakingStartWeek,
            currentWeek,
            mstake.stakingDuration,
            mstake.paidDuration,
            getShares(uint16(mstake.stakingDuration))
        );
        // need to update state (paidDuration) in next step
        return payout;
    }

    function canBeUnstaked(StakedApe memory mstake, uint256 currentWeek) internal pure returns(bool){
        if (mstake.stakingStartWeek == 0) return false;
        return (currentWeek - mstake.stakingStartWeek >= mstake.stakingDuration);
    }
}