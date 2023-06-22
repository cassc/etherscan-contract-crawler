// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISmurfMint {
    function mintHackerSmurf(uint _qty) external;
    function mintBucketSmurf(address _to, uint _qty) external;
    function mintBlueListSmurf(address _to, uint _qty) external;
    function mintFrensSmurf(address _to, uint _qty) external;
    function mintCrystalSmurfs(uint[] memory _crystalIds, bytes memory _signatures) external payable;
}