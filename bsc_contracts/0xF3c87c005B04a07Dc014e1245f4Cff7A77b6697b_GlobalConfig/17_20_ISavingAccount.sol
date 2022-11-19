// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ISavingAccount {
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        address _globalConfig,
        address _poolRegistry,
        uint256 _poolId
    ) external;

    function configure(
        address _baseToken,
        address _miningToken,
        uint256 _maturesOn
    ) external;

    function toCompound(address, uint256) external;

    function fromCompound(address, uint256) external;

    function approveAll(address _token) external;
}