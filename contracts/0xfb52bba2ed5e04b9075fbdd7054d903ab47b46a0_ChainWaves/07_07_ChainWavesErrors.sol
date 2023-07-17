// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ChainWavesErrors {
    error SoldOut();
    error NotLive();
    error MintPrice();
    error MaxThree();
    error PublicMinted();
    error SnowcrashMinted();
    error NotToad();
    error FreeMintDone();
    error NotSnowcrashList();
    error ReserveClosed();
    error SelfMintOnly();
    error ArrayLengths();
    error NonExistantId();
    error Stap();
    error WithdrawFail();
    error MintZero();
}