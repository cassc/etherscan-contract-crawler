//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IAddressContract {

    function getDao() external view returns (address);
    
    function getTreasury() external view returns (address);
   
    function getScarabNFT() external view returns (address);
    
    function getScarab() external view returns (address);

    function getBarac() external view returns (address);
    
}