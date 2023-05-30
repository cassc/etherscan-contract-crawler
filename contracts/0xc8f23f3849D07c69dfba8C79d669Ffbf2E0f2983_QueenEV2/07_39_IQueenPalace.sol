// SPDX-License-Identifier: MIT

/// @title Interface for Queen Staff Contract

pragma solidity ^0.8.9;

import {IQueenLab} from "../interfaces/IQueenLab.sol";
import {IQueenTraits} from "../interfaces/IQueenTraits.sol";
import {IQueenE} from "../interfaces/IQueenE.sol";
import {IQueenAuctionHouse} from "../interfaces/IQueenAuctionHouse.sol";

interface IQueenPalace {
    function royalMuseum() external view returns (address);

    function isOnImplementation() external view returns (bool status);

    function artist() external view returns (address);

    function isArtist(address addr) external view returns (bool);

    function dao() external view returns (address);

    function daoExecutor() external view returns (address);

    function RoyalTowerAddr() external view returns (address);

    function developer() external view returns (address);

    function isDeveloper(address devAddr) external view returns (bool);

    function minter() external view returns (address);

    function QueenLab() external view returns (IQueenLab);

    function QueenTraits() external view returns (IQueenTraits);

    function QueenAuctionHouse() external view returns (IQueenAuctionHouse);

    function QueenE() external view returns (IQueenE);

    function whiteListed() external view returns (uint256);

    function isWhiteListed(address _addr) external view returns (bool);

    function QueenAuctionHouseProxyAddr() external view returns (address);
}