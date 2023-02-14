// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IDiceGame {
    function calculateBet(
        uint16 lowerNumber,
        uint16 upperNumber,
        uint256 betAmount
    )
        external
        view
        returns (
            uint256 winningChance,
            uint256 multiplier,
            uint256 prizeAmount
        );

    function getAvailablePrize(IERC20Upgradeable token)
        external
        view
        returns (uint256);

    function MAX_NUMBER() external view returns (uint16);

    function houseEdge() external view returns (uint16);

    function maxBetAmount() external view returns (uint256);
}