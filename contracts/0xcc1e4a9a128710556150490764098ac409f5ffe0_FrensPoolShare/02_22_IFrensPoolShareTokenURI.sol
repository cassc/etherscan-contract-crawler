// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


interface IFrensPoolShareTokenURI {
  function tokenURI ( uint256 id ) external view returns ( string memory );
}