// SPDX-License-Identifer: MIT
pragma solidity >=0.8.0;

interface IFeeMinter {
    function totalToMintPerBlock() external view returns (uint256);
    function minters(uint256 index) external view returns (address);
    function setTotalToMintPerBlock(uint256 _totalToMintPerBlock) external;
    function setToMintPercents(address[] calldata _minters, uint256[] calldata _toMintPercents) external;
    function getToMintPerBlock(address _minter) external view returns (uint256);
    function getMinters() external view returns (address[] memory);
    function getToMintPercent(address _minter) external view returns (uint256);
}