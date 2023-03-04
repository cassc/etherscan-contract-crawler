// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IErc20ForFactory.sol';

interface IErc20ForFactoryFactory {
    /// @dev creates specific erc20 contract
    function create(string memory name, string memory symbol, uint8 decimals) external returns (IErc20ForFactory);
}