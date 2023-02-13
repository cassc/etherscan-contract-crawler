// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IReservesInteractor {
    function reduceAllReserves(address len) external;
    function reduceReserves(address market) external returns (uint reservesReduced);
}