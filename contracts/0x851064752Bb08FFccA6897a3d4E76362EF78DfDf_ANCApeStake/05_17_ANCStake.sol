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

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FeeSplitter.sol";

abstract contract ANCStake is Ownable{

    struct TwoWeekInfo{
        uint96 tokensEvenWeek;
        uint32 totalSharesEvenWeek;
        uint96 tokensOddWeek;
        uint32 totalSharesOddWeek;
    }

    uint256 public constant MAX_STAKING_DURATION = 52;
    uint256 public constant ONE_WEEK = 604800; // 1 week = 604800
    uint256 public tenthPercentPerWeek;
    uint256 public stakingStart;

    FeeSplitter internal _danceSplitter;

    uint256 internal _reservedTokens;

    mapping(uint256 => TwoWeekInfo) private _weeklyInfo;

    constructor(uint256 tenthPercentPerWeek_){
        tenthPercentPerWeek = tenthPercentPerWeek_;
    }

    modifier stakingGate(uint32 duration){
        require(stakingStart > 0, "Staking has not started");
        require(duration >= 1, "Minimum staking period 1 week");
        require(duration <= MAX_STAKING_DURATION, "Maximum staking period 1 year");
        _;
    }

    /* External Functions */

    function payoutReward(uint256) virtual external;

    function setRewardSplitter(address splitterAddress) external onlyOwner {
        require(_danceSplitter == FeeSplitter(address(0)), "Splitter already set");
        require(splitterAddress != address(0), "splitter cannot be 0 address");
        _danceSplitter = FeeSplitter(splitterAddress);
    }

    function setStakingStart() external onlyOwner {
        require(stakingStart == 0, "Staking has already started.");
        stakingStart = block.timestamp;
    }

    function setTenthPercentPerWeek(uint256 tenthPercentPerWeek_) external onlyOwner {
        require(tenthPercentPerWeek_ > 0, "Value must be bigger than 0");
        tenthPercentPerWeek = tenthPercentPerWeek_;
    }

    function getFundsForWeeksLowerBound(uint256 startWeek, uint256 endWeek) external view returns(uint256){
        uint256 currentWeek = getCurrentWeek();
        uint256 currentFunds = getAvailableFunds();
        uint256 lastUnreservedWeek = findLastUnreservedWeek(currentWeek);
        uint256 fundsForWeeks = 0;
        for (uint256 week = startWeek; week < lastUnreservedWeek; week++) {
            fundsForWeeks += getBasePayoutForWeek(week);
        }
        uint256 basePayoutForWeek;
        for (uint256 week = lastUnreservedWeek; week < currentWeek; week++) {
            if (getSharesForWeek(week) > 0) {
                basePayoutForWeek = currentFunds * tenthPercentPerWeek / 1000;
                currentFunds -= basePayoutForWeek;
                fundsForWeeks += basePayoutForWeek;
            }
        }
        for (uint256 week = currentWeek; week < endWeek; week++) {
            basePayoutForWeek = currentFunds * tenthPercentPerWeek / 1000;
            currentFunds -= basePayoutForWeek;
            fundsForWeeks += basePayoutForWeek;
        }
        return fundsForWeeks;
    }

    /* Public Functions */

    function getStakedIDs(address) public view virtual returns(uint256[] memory);

    function getNumStaked(address) public view virtual returns(uint256);

    function getAvailableFunds() public view returns(uint256){
        return _danceSplitter.balanceOf(address(this)) - _reservedTokens;
    }

    function getBasePayoutForWeek(uint256 week) public view returns(uint256){
        if(week & 1 == 0){
            return _weeklyInfo[week].tokensEvenWeek;
        }else{
            return _weeklyInfo[week-1].tokensOddWeek;
        }
    }

    function getSharesForWeek(uint256 week) public view returns(uint256){
        if(week & 1 == 0){
            return _weeklyInfo[week].totalSharesEvenWeek;
        }else{
            return _weeklyInfo[week-1].totalSharesOddWeek;
        }
    }

    function getCurrentWeek() public view returns(uint256){
        return timestamp2week(block.timestamp);
    }

    /* Internal Functions */

    function addSharesToWeeks(uint256 startWeek, uint256 duration, uint256 amount) internal{
        for (uint256 i = startWeek; i < startWeek+duration; i++) {
            if(i & 1 == 0){
                _weeklyInfo[i].totalSharesEvenWeek += uint32(amount);
            }else{
                _weeklyInfo[i-1].totalSharesOddWeek += uint32(amount);
            }
        }
    }

    function reserveAndGetTokens(uint256 balance) internal returns(uint256){
        //console.log("balance:", _dance.balanceOf(address(this)));
        uint256 newReserved = (balance - _reservedTokens) * tenthPercentPerWeek / 1000;
        _reservedTokens += newReserved;
        //console.log("reserved tokens:", _reservedTokens);
        return newReserved;
    }

    function reserveForPastWeeks(uint256 currentWeek) internal{
        // find last reserved Week
        uint256 lastUnreservedWeek = findLastUnreservedWeek(currentWeek);
        //console.log("current week", currentWeek);
        //console.log("last unreserved week ", lastUnreservedWeek);
        if (lastUnreservedWeek >= currentWeek) return;
        // reserved unclaimed weeks
        uint256 balance = _danceSplitter.balanceOf(address(this));
        for (uint256 week = lastUnreservedWeek; week < currentWeek; week++) {
            if(week & 1 == 0){
                if (_weeklyInfo[week].totalSharesEvenWeek > 0) {
                    _weeklyInfo[week].tokensEvenWeek = uint96(reserveAndGetTokens(balance));
                    //console.log("tokens for week", week, _weeklyInfo[week].tokensEvenWeek);
                }
            } else {
                if (_weeklyInfo[week-1].totalSharesOddWeek > 0) {
                    _weeklyInfo[week-1].tokensOddWeek = uint96(reserveAndGetTokens(balance));
                    //console.log("tokens for week", week, _weeklyInfo[week-1].tokensOddWeek);
                }
            }
        }
    }

    function findLastUnreservedWeek(uint256 currentWeek) internal view returns(uint256){
        uint256 week = currentWeek;
        uint256 tokensForWeek;
        while(week > 1) {
            week -= 1;
            if(week & 1 == 0){
                tokensForWeek = _weeklyInfo[week].tokensEvenWeek;
            } else {
                tokensForWeek = _weeklyInfo[week-1].tokensOddWeek;
            }
            if (tokensForWeek > 0) return week+1;
        }
        return 0;
    }

    function getStakingReward(
        uint256 stakingStartWeek,
        uint256 currentWeek,
        uint256 duration,
        uint256 paidDuration,
        uint256 shares
    ) internal view returns(uint256){
        if (stakingStartWeek + paidDuration >= currentWeek) return 0; // no weeks to pay out
        return _getStakingReward(stakingStartWeek+paidDuration, min(currentWeek, stakingStartWeek+duration), shares);
    }

    function _getStakingReward(uint256 startWeek, uint256 endWeek, uint256 shares) internal view returns(uint256){
        uint256 payout = 0;
        uint256 weeklyShares;
        for(uint256 i = startWeek; i < endWeek; i++){
            if(i & 1 == 0){
                weeklyShares = _weeklyInfo[i].totalSharesEvenWeek;
            } else {
                weeklyShares = _weeklyInfo[i-1].totalSharesOddWeek;
            }
            payout += (getBasePayoutForWeek(i) * shares) / weeklyShares;
        }
        return payout;
    }

    function _getAvailablePayout(uint256 startWeek, uint256 endWeek, uint256 currentWeek, uint256 shares)
        internal
        view
        returns (uint256)
    {
        uint256 currentFunds = getAvailableFunds();
        endWeek = min(endWeek, currentWeek);
        uint256 lastUnreservedWeek = findLastUnreservedWeek(currentWeek);
        uint256 payout = 0;
        uint256 basePayoutForWeek;
        uint256 sharesForWeek;
        for (uint256 week = startWeek; week < endWeek; week++) {
            sharesForWeek = getSharesForWeek(week);
            if (sharesForWeek > 0) {
                if (week < lastUnreservedWeek) { // week has funds reserved
                    basePayoutForWeek = getBasePayoutForWeek(week);
                } else { // week does not have funds reserved
                    basePayoutForWeek = currentFunds * tenthPercentPerWeek / 1000;
                    currentFunds -= basePayoutForWeek;
                }
                payout += (basePayoutForWeek * shares) / sharesForWeek;
            }
        }
        return payout;
    }

    function timestamp2week (uint256 timestamp) internal view returns(uint256) {
        return ((timestamp - stakingStart) / ONE_WEEK)+1;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a <= b) ? a : b;
    }

}