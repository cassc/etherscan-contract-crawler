// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IFarmManager {
    function getPaused() external view returns(bool);
    function getBurnRate() external view returns(uint256);
    function getBurnRatio() external view returns(uint256);
    function getUnstakeEpochs() external view returns(uint256);
    function getRedistributor() external view returns(address);
    function getLpLock() external view returns(address);
    function getBurnValley() external view returns(address);
}