//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "../core/Treasury3/library/EGoldUtils.sol";

interface IEGoldIdentity {

    function setUser( address _parent ,  EGoldUtils.userData memory userData) external;

    function setRank( address _addr,  uint256 _rank) external;

    function setParent( address _addr,  address _parent) external;

    function setSales( address _addr, uint256 _sn , uint256 _sales) external;

    function fetchUser( address _parent ) external view returns ( EGoldUtils.userData memory );

    function fetchParent( address _addr ) external view returns ( address );

    function fetchRank( address _addr ) external view  returns ( uint256 );

    function fetchSales( address _addr ) external view  returns ( uint256 , uint256 );

}