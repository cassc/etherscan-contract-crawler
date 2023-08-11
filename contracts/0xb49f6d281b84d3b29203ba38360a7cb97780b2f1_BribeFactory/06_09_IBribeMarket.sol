// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBribeMarket {
    /**
        @notice Initialize the contract
        @param  _bribeVault  Bribe vault address
        @param  _admin       Admin address
        @param  _protocol    Protocol name
        @param  _maxPeriods  Maximum number of periods
        @param  _periodDuration  Period duration
     */
    function initialize(
        address _bribeVault,
        address _admin,
        string calldata _protocol,
        uint256 _maxPeriods,
        uint256 _periodDuration
    ) external;
}