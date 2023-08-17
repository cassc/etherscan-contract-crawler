// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface ITreasuryAndStakedTokenFactory {
    function create(
        address _qwa,
        address[] calldata _backingTokens,
        uint256[] calldata _backingAmounts,
        string[2] calldata _nameAndSymbol,
        bool _qwnBackingToken
    ) external returns (address _treasuryAddress, address _sQWAAddress);

    function setDistributorAndInitialize(
        address _distributor,
        address _staking,
        address _treasury,
        address _sQWA,
        address _owner
    ) external;
}