/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IRoulettePot {
    struct Casino {
        address tokenAddress;
        string tokenName;
        uint256 liquidity;
        uint256 maxBet;
        uint256 minBet;
        uint256 fee;
    }
    struct Bet {
        /* 5: number, 4: even, odd, 3: 18s, 2: 12s, 1: row, 0: black, red */
        uint8 betType;
        uint8 number;
        uint256 amount;
    }

    event RouletteWon(uint256 tokenId, address winner, uint256 nonce, uint256 amount);
    event RouletteLost(uint256 tokenId, address loser, uint256 nonce);
    event TransferFailed(uint256 tokenId, address to, uint256 amount);

    function addCasino(
        uint256 tokenId,
        address tokenAddress,
        string memory tokenName,
        uint256 maxBet,
        uint256 minBet,
        uint256 fee
    ) external;

    function getMaximumReward(Bet[] calldata bets) external pure returns (uint256);

    function placeBetsWithTokens(uint256 tokenId, Bet[] calldata bets) external;

    function placeBetsWithEth(uint256 tokenId, Bet[] calldata bets) external payable;

    function addLiquidtyWithTokens(uint256 tokenId, uint256 amount) external;

    function removeLiquidtyWithTokens(uint256 tokenId, uint256 amount) external;

    function addLiquidtyWithEth(uint256 tokenId, uint256 amount) external payable;

    function removeLiquidtyWithEth(uint256 tokenId, uint256 amount) external;
}