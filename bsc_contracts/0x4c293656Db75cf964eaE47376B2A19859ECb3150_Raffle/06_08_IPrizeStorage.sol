// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IPrizeMatrix.sol";
import "./IRaffleResults.sol";

interface IPrizeStorage{
        function setPrizes(
        IRaffleResults.RaffleResults memory raffleResults,
        IPrizeMatrix.PrizeLevel[] memory prizeMatrix
    ) external payable;

    function checkForPrize(address contractAddress, uint32 raffleId, address playerAddress) external returns (uint);

    function getRaffleDrawBalance(address contractAddress, uint32 raffleId) external view returns (uint);

    function getRaffleDrawTimestamp(address contractAddress, uint32 raffleId) external view returns (uint);

    function prizePayout(address contractAddress, uint32 raffleId) external;
}