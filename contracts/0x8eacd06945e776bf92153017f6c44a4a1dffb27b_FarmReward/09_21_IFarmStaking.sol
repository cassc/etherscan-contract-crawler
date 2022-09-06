// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Model.sol";

interface IFarmStaking {
    function getStakingRecords(address userAddr) external view returns(Model.StakingRecord[] memory);
    function getCurrentStakingCount(address userAddr) external view returns(uint256);
    function getStakingIndexs(address userAddr) external view returns(uint256[] memory);
}