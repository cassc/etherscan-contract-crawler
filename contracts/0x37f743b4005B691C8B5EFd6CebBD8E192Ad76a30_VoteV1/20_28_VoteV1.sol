// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./ArtV1.sol";
import "../foundation/FoundBank.sol";

contract VoteV1 {
    ArtV1 private _art;
    FoundBank private _bank;

    function submitAndVote(
        address payer,
        address minter,
        uint amount,
        ArtParams memory params,
        ImageV1 memory image
    ) external returns (uint) {
        uint artId = _art.createArt(params, image);
        _bank.vote(CoinVote(payer, minter, artId, amount));
        return artId;
    }

    constructor(ArtV1 art_, FoundBank bank_) {
        _bank = bank_;
        _art = art_;
    }
}