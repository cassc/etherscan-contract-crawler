// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWGFeeDistributor {
    function setWayGatePartnersAmount(
        uint256 _partenrsAmount
    ) external returns (uint256);

    function setWayGateAirdropTokenAmount(
        uint256 _airdropAmount
    ) external returns (uint256);

    function setWayGateAirdropNativeTokenAmount(
        uint256 _airdropNativeTokenAmount
    ) external returns (uint256);

    function setWayGatePlatformFeeAmount(
        uint256 _wayGateplatformFeeAmount
    ) external returns (uint256);
}