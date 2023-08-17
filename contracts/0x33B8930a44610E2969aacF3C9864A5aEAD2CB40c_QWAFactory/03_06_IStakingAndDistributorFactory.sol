// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface IStakingAndDistributorFactory {
    function create(
        address _qwa,
        address _sQWA,
        address _treasury,
        address _owner
    ) external returns (address _stakingAddress, address _distributorAddress);
}