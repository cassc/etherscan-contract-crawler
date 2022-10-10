// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import {LibNFTStorage} from "./LibNFTStorage.sol";
import {LibRoyaltyStorage} from "./LibRoyaltyStorage.sol";

struct AppStorage {
    LibNFTStorage nftStorage;
    LibRoyaltyStorage royaltyStorage;
    mapping(uint256 => uint256) flaggedPasses;
    mapping(uint256 => uint256) reversedFlaggedPasses;
    uint256  flaggedPassHead;
    mapping(address => address)  flaggedAddresses;
    mapping(address => address)  reversedFlaggedAddresses;
    address  flaggedAddressHead;
    bool  isRefundingGas;
    uint256  maxRefundAmount;
    uint256  refundGasBuffer;
    uint256  flaggedAddressesCount;
    uint256  flaggedPassesCount;
    mapping(address => bool) adminTransferUsers;
    address operatorFilter;
}