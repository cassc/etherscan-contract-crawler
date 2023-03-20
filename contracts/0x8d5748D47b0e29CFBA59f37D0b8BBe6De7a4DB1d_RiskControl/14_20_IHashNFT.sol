// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IHashNFT {
    
    function dispatcher() external view returns(address); 

    function sold() external view returns(uint256);

}