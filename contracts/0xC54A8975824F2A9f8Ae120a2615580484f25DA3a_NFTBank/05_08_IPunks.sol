pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IPunks {

    function punkIndexToAddress(uint punkIndex) external view returns (address);
    function totalSupply() external view returns (uint256);
    
}