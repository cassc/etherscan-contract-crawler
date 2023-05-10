// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IHam {
    function rely(address usr) external;
    function deny(address usr) external;
    function eFR(address account) external;
    function updateGasForTransfer(uint256 newGasForTransfer) external;
    function uCW(uint256 newClaimWait) external;
    function getLastProcessedIndex() external view returns(uint256);
    function getMagnifiedDividendPerShare() external view returns(uint256);
    function getNumberOfTokenHolders() external view returns(uint256);
    function getClaimWait() external view returns(uint256);
    function getAccount(address _account)external view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable);
    function pA(address payable account, bool automatic) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function getTotalPendingDividends() external returns(uint256);
    function setTotalPendingDividends(uint256 newPending) external;
    function totalRewardsDistributed() external view returns(uint256);
    function dividendOf(address _owner) external view returns(uint256);
    function sb(address payable account, uint256 newBalance) external;
    function p(uint256 gas) external returns (uint256, uint256, uint256);
    function _setUserHasCustomRewardToken(address user, bool boolean) external;
    function _userCustomRewardToken(address user) external view returns (address);
    function _setUserCustomRewardToken(address user, address rewardToken) external;
    function _userHasCustomRewardToken(address user) external view returns (bool);
    function setBalance(address payable account) external; 
}