// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStarkEx  {
    function getEthKey(
        uint256 starkKey
    ) external view returns (address);

    function isMsgSenderKeyOwner(
        uint256 ownerKey
    ) external view returns (bool);

    function registerEthAddress(
        address ethKey,
        uint256 starkKey,
        bytes calldata starkSignature
    ) external;

    function depositERC20(
        uint256 starkKey,
        uint256 assetType,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    function getWithdrawalBalance(
        uint256 starkKey,
        uint256 assetId
    ) external view returns (uint256 balance);

    function withdraw(
        uint256 starkKey, 
        uint256 assetId
    ) external;

    function forcedWithdrawalRequest(
        uint256 starkKey,
        uint256 vaultId,
        uint256 quantizedAmount,
        bool premiumCost
    ) external;
}