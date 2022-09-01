// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IIntegration} from './IIntegration.sol';

/**
 * @title IStrategyFactory
 * @author Babylon Finance
 *
 * Interface for the strategy factory
 */
interface IStrategyFactory {
    function createStrategy(
        string memory _name,
        string memory _symbol,
        address _strategist,
        address _garden,
        uint256[] calldata _stratParams
    ) external returns (address);
}