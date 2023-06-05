// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

interface IEmission {
    function setDistribution(uint _distributedPerBlock) external;
    function withdraw() external;
    function withdrawable() external view returns (uint);
    function distributedPerBlock() external view returns (uint);
}