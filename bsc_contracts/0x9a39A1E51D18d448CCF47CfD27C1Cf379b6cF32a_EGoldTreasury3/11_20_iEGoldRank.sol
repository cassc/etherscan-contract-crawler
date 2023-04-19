//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "../core/Treasury3/library/EGoldUtils.sol";

interface IEGoldRank {

    function setRank( uint256 _rank , EGoldUtils.Ranks memory _levelDetails ) external;

    function fetchRank(  uint256 _rank ) external view returns ( EGoldUtils.Ranks memory );

    function fetchRanklimit(  uint256 _rank ) external view returns ( uint256 );

    function fetchRankPercent(  uint256 _rank ) external view returns ( uint256 );

}