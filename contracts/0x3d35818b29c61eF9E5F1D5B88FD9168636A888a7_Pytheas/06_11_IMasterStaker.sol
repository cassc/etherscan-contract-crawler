// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IMasterStaker {

 function masterStake(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external;

 function masterUnstake(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external;

 function masterClaim(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external;
}