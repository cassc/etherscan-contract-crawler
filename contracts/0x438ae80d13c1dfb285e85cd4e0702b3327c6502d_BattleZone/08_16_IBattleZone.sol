// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBattleZone {
    event Deposit(
        address indexed staker,
        address contractAddress,
        uint256 tokensAmount
    );
    event Withdraw(
        address indexed staker,
        address contractAddress,
        uint256 tokensAmount
    );
    event AutoDeposit(
        address indexed contractAddress,
        uint256 tokenId,
        address indexed owner
    );
    event WithdrawStuckERC721(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    function deposit(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenRarities,
        bytes calldata signature
    ) external;

    function withdraw(address contractAddress, uint256[] memory tokenIds)
        external;

    function depositToolboxes(
        uint256 beepBoopTokenId,
        uint256[] memory toolboxTokenIds
    ) external;

    function withdrawToolboxes(uint256[] memory toolboxTokenIds) external;

    function getAccumulatedAmount(address staker)
        external
        view
        returns (uint256);
}