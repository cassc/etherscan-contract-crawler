// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IErc20ForFactoryFactory.sol';
import './Erc20ForFactory.sol';

contract Erc20ForFactoryFactory is IErc20ForFactoryFactory {
    function create(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (IErc20ForFactory) {
        return new Erc20ForFactory(name, symbol, msg.sender, decimals);
    }
}