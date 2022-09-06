// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IGarden} from '../interfaces/IGarden.sol';

/**
 * @title IStrategy
 * @author Babylon Finance
 *
 * Interface for strategy
 */
interface IStrategy {
    function initialize(
        address _strategist,
        address _garden,
        address _controller,
        uint256 _maxCapitalRequested,
        uint256 _stake,
        uint256 _strategyDuration,
        uint256 _expectedReturn,
        uint256 _maxAllocationPercentage,
        uint256 _maxGasFeePercentage,
        uint256 _maxTradeSlippagePercentage
    ) external;

    function resolveVoting(
        address[] calldata _voters,
        int256[] calldata _votes,
        uint256 fee
    ) external;

    function updateParams(uint256[5] calldata _params) external;

    function sweep(
        address _token,
        uint256 _newSlippage,
        bool _sendToMultisig
    ) external;

    function setData(
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes memory _opEncodedData
    ) external;

    function executeStrategy(uint256 _capital, uint256 fee) external;

    function getNAV() external view returns (uint256);

    function opEncodedData() external view returns (bytes memory);

    function getOperationsCount() external view returns (uint256);

    function getOperationByIndex(uint8 _index)
        external
        view
        returns (
            uint8,
            address,
            bytes memory
        );

    function finalizeStrategy(
        uint256 fee,
        string memory _tokenURI,
        uint256 _minReserveOut
    ) external;

    function unwindStrategy(uint256 _amountToUnwind, uint256 _strategyNAV) external;

    function invokeFromIntegration(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory);

    function invokeApprove(
        address _spender,
        address _asset,
        uint256 _quantity
    ) external;

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken
    ) external returns (uint256);

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _overrideSlippage
    ) external returns (uint256);

    function handleWeth(bool _isDeposit, uint256 _wethAmount) external;

    function signalUnlock(uint256 _fee) external;

    function updateStrategyRewards(uint256 _newTotalBABLRewards, uint256 _newCapitalReturned) external;

    function getStrategyState()
        external
        view
        returns (
            address,
            bool,
            bool,
            bool,
            uint256,
            uint256,
            uint256
        );

    function getStrategyRewardsContext()
        external
        view
        returns (
            address,
            uint256[15] memory,
            bool[2] memory
        );

    function isStrategyActive() external view returns (bool);

    function getUserVotes(address _address) external view returns (int256);

    function strategist() external view returns (address);

    function enteredAt() external view returns (uint256);

    function enteredCooldownAt() external view returns (uint256);

    function stake() external view returns (uint256);

    function strategyRewards() external view returns (uint256);

    function maxCapitalRequested() external view returns (uint256);

    function maxAllocationPercentage() external view returns (uint256);

    function maxTradeSlippagePercentage() external view returns (uint256);

    function maxGasFeePercentage() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function duration() external view returns (uint256);

    function totalPositiveVotes() external view returns (uint256);

    function totalNegativeVotes() external view returns (uint256);

    function capitalReturned() external view returns (uint256);

    function capitalAllocated() external view returns (uint256);

    function garden() external view returns (IGarden);
}