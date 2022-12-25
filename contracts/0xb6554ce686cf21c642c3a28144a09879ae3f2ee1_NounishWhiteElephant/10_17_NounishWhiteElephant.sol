// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {WhiteElephant} from "./base/WhiteElephant.sol";
import {NounishChristmasNFT, NounishChristmasMetadata} from "./NounishChristmasNFT.sol";

contract NounishWhiteElephant is WhiteElephant, Owned {
    error InsufficientPayment();
    error DoneForNow();

    uint256 public participantFee;
    uint256 public endTimestamp;

    constructor(uint256 fee, uint256 _endTimestamp, NounishChristmasMetadata _metadata) Owned(msg.sender) {
        nft = new NounishChristmasNFT(_metadata);
        participantFee = fee;
        endTimestamp = _endTimestamp;
    }

    /// @inheritdoc WhiteElephant
    function startGame(Game calldata game) public payable override returns (bytes32 _gameID) {
        if (block.timestamp > endTimestamp) {
            revert DoneForNow();
        }

        if (msg.value < game.participants.length * participantFee) {
            revert InsufficientPayment();
        }
        return super.startGame(game);
    }

    /// @inheritdoc WhiteElephant
    function open(Game calldata game) public override {
        if (block.timestamp > endTimestamp) {
            revert DoneForNow();
        }
        super.open(game);
    }

    /// @inheritdoc WhiteElephant
    function steal(Game calldata game, uint256 tokenID) public override {
        if (block.timestamp > endTimestamp) {
            revert DoneForNow();
        }
        super.steal(game, tokenID);
    }

    function transferFees(address to, uint256 amount) external onlyOwner {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function setEndTimestamp(uint256 _new) external onlyOwner {
        endTimestamp = _new;
    }

    function updateMetadata(NounishChristmasMetadata _metadata) external onlyOwner {
        NounishChristmasNFT(address(nft)).updateMetadata(_metadata);
    }
}