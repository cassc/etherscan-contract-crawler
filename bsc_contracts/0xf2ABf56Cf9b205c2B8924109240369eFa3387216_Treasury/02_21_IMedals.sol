// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMedals {
    
    function accountMedalTokenIds(address _address, uint256 _medalId) external view returns (uint256[] memory);

    function getMedalInfos(uint256[] memory tokenIds) external returns (uint256[] memory, uint256[] memory);
}