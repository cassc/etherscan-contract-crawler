// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBee {
    function stake(address staker, uint256 tokenId) external;
    function unstake(address unstaker, uint256 tokenId) external;
    function mint(address sender, uint256 amount) external;
    function restorePowerOfBee(address owner, uint256 tokenId, uint256 restorePeriods) external;

    function realOwnerOf(uint256 tokenId) external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function isAlreadyStaked(uint256 tokenId) external view returns (bool);
    function getPowerReductionPeriods(uint256 tokenId) external view returns (uint256);
    function getLastAction(uint256 tokenId) external view returns (uint88);
    function getPowerCycleStart(uint256 tokenId) external view returns (uint88);

    function powerCycleBasePeriod() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}