// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.8.2;

interface IBLL 
{
    function getPointsForTokenIDs(uint32[] memory nftIds) external view returns (uint256);
    function getPointsForTokenID(uint32 nftId) external view returns (uint256);
    function checkSeriesForTokenIDs(uint32 seriesId, uint32[] memory tokenIds) external view returns (bool);
    function getPointsForSeries(uint32 seriesId, uint32[] memory tokenIds) external view returns (uint256);
}