// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseDistributor {
    enum RewardType{
        TOKEN,
        CURRENCY
    }

    struct RewardInfo{
        string name;
        address rewardAddress;
        uint256 decimals;
    }

    function getShares(address shareholder) external view returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised);
    function deposit() external payable;
    function rewardCurrency() external view returns(string memory);
    function enroll(address shareholder) external;
    function claimDividend() external;

    function setShares(address sendingShareholder, uint256 senderBalance, address receivingShareholder, uint256 receiverBalance) external;

}