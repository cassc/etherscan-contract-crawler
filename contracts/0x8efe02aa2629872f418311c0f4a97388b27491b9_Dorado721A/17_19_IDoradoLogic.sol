// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IDoradoLogic {
    struct MintData {
        uint64 walletMaxLimit;
        uint8 stage;
        uint64 stageLimit;
        uint64 walletStageLimit;
        uint64 quantity;
        uint256 price;
        uint256 nonce;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint64 maxTokens_,
        bool burnable_,
        uint96 feeNumerator_,
        address treasury_,
        string[] calldata uris
    ) external;
}