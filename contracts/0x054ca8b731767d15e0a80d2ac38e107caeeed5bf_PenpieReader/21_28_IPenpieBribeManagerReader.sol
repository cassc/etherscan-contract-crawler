// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


interface IPenpieBribeManagerReader {
    function getCurrentEpochEndTime() external view returns(uint256 endTime);
    function voteManager() external view returns(address);
    struct IBribe {
        address _token;
        uint256 _amount;
    } 
    function getBribesInAllPools(uint256 _epoch) external view returns (IBribe[][] memory);
    function exactCurrentEpoch() external view returns(uint256);
    function getApprovedTokens() external view returns(address[] memory);
}