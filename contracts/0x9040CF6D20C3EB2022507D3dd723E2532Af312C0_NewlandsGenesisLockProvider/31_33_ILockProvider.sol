// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILockProvider {
    function onTokenLocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external;

    function onTokenUnlocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external;
}