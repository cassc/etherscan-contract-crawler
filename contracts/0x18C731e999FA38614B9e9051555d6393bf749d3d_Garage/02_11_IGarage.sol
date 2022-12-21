// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGarage {

    function StakedAndLocked(uint16) external view returns(bool);
    function StakedNFTInfo(uint16) external view returns(uint16, uint80, uint80);
    
}