// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './enums/TokenType.sol';
import './structs/DistributedUserInfo.sol';

interface IDistributedRewardsPot {
    function storePurchaseStatistics(
        address user,
        TokenType tokenType,
        uint256 purchaseValue,
        uint256 rewardAmount
    ) external;

    function addMintCollection(
        TokenType tokenType,
        uint256 takenFeeAmount
    ) external;

    function withdrawUnclaimedRewards(
        uint256 month,
        address admin,
        TokenType tokenType
    ) external;

    function noteUserMintParticipation(
        address userAddress,
        TokenType tokenType
    ) external;

    function getUserInfoForCurrentMonth(
        address userAddress,
        TokenType tokenType
    ) external view returns (UserInfoDistributed memory);
}