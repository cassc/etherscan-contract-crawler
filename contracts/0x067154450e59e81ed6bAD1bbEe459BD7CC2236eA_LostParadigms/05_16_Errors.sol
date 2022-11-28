// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

error CallerIsNotEOA();
error PurchaseExceedsMaxSupply();
error UnrecognizedHash();
error AllowlistNotActive();
error NotEnoughETHSent();
error MaxAllocationExceeded();
error FreeMintAlreadyClaimed();
error MaxPublicAllocationExceeded();
error PublicMintNotActive();
error MaxFreeAllocationExceeded();
error MintIsHalted();
error FirstCommitCompleted();
error SecondCommitCompleted();
error FirstCommitNotCompleted();
error SecondCommitNotCompleted();
error FirstRevealCompleted();
error SecondRevealCompleted();
error TooEarlyForReveal();
error FirstRevealIncomplete();