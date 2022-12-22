// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './IRoles.sol';

interface IRevealable is IRoles {
    error CannotTransferLink();

    error SeedIsAlreadySet();

    event CallbackGasLimitUpdated(uint32 callbackGasLimit);

    event DefaultURIUpdated(string defaultURI);

    event SeedUpdated(uint256 seed);

    event RandomnessFailed(
        uint256 indexed timestamp,
        uint256 requestId,
        uint256 randomWord
    );

    event RandomnessRequested(uint256 indexed timestamp, uint256 requestId);

    event RandomnessSucceeded(
        uint256 indexed timestamp,
        uint256 requestId,
        uint256 randomWord
    );

    event RevealedBaseURIUpdated(string revealedBaseURI);

    function requestRandomSeed() external;

    function setCallbackGasLimit(uint32 callbackGasLimit) external;

    function setDefaultURI(string memory defaultURI) external;

    function setRevealedBaseURI(string memory revealedBaseURI) external;

    function setSeed(uint256 seed) external;

    function withdrawLink() external;

    function isRevealed() external view returns (bool);
}