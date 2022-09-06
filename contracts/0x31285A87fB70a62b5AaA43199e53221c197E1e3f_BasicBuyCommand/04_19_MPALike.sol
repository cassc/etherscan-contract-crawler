//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface MPALike {
    struct CdpData {
        address gemJoin;
        address payable fundsReceiver;
        uint256 cdpId;
        bytes32 ilk;
        uint256 requiredDebt;
        uint256 borrowCollateral;
        uint256 withdrawCollateral;
        uint256 withdrawDai;
        uint256 depositDai;
        uint256 depositCollateral;
        bool skipFL;
        string methodName;
    }

    struct AddressRegistry {
        address jug;
        address manager;
        address multiplyProxyActions;
        address lender;
        address exchange;
    }

    struct ExchangeData {
        address fromTokenAddress;
        address toTokenAddress;
        uint256 fromTokenAmount;
        uint256 toTokenAmount;
        uint256 minToTokenAmount;
        address exchangeAddress;
        bytes _exchangeCalldata;
    }

    function increaseMultiple(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;

    function decreaseMultiple(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;

    function closeVaultExitCollateral(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;

    function closeVaultExitDai(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;
}