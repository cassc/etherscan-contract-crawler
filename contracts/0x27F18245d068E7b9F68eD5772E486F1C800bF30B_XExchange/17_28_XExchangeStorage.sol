// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWeth} from "../interfaces/IWeth.sol";
import {ITransferManagerSelector} from "../interfaces/ITransferManagerSelector.sol";
import {IRoyaltyEngine} from "../interfaces/IRoyaltyEngine.sol";
import {IMarketplaceFeeEngine} from "../interfaces/IMarketplaceFeeEngine.sol";
import {IStrategyManager} from "../interfaces/IStrategyManager.sol";
import {ICurrencyManager} from "../interfaces/ICurrencyManager.sol";

contract XExchangeStorage {
    bytes32 public domainSeperator;
    IWeth public weth;

    ITransferManagerSelector public transferManager;
    IRoyaltyEngine public royaltyEngine;
    IMarketplaceFeeEngine public marketplaceFeeEngine;
    IStrategyManager public strategyManager;
    ICurrencyManager public currencyManager;
    mapping(address => uint256) public userMinNonce;
    mapping(bytes32 => bool) public orderStatus;
}