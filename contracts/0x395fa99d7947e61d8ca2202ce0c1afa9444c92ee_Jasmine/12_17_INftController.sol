// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct WinData {
    address winnerAddress;
    address nftAddress;
    uint256 tokenId;
}

interface INftController {
    event OnGameOver(
        address indexed account,
        address nftAddress,
        uint256 tokenId
    );

    function maxMintCount() external view returns (uint256);

    function mintedCount() external view returns (uint256);

    function addMintedCount(uint256 countToAdd) external;

    function lappsedMintCount() external view returns (uint256);

    function isGameOver() external view returns (bool);

    function checkCanMint() external view;

    function setGameOver(WinData calldata data) external;

    function winData() external view returns (WinData memory);

    function startGame() external;

    function gameStarted() external view returns (bool);

    function startGameTime() external view returns (uint256);
}