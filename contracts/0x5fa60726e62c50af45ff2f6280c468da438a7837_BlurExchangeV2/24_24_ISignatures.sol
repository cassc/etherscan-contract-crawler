// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    TakeAsk,
    TakeBid,
    TakeAskSingle,
    TakeBidSingle,
    Order,
    OrderType,
    Listing
} from "../lib/Structs.sol";

interface ISignatures {
    error Unauthorized();
    error ExpiredOracleSignature();
    error UnauthorizedOracle();
    error InvalidOracleSignature();
    error InvalidDomain();

    function oracles(address oracle) external view returns (uint256);
    function nonces(address user) external view returns (uint256);
    function blockRange() external view returns (uint256);

    function verifyDomain() external view;

    function information() external view returns (string memory version, bytes32 domainSeparator);
    function hashListing(Listing memory listing) external pure returns (bytes32);
    function hashOrder(Order memory order, OrderType orderType) external view returns (bytes32);
    function hashTakeAsk(TakeAsk memory inputs, address _caller) external pure returns (bytes32);
    function hashTakeBid(TakeBid memory inputs, address _caller) external pure returns (bytes32);
    function hashTakeAskSingle(TakeAskSingle memory inputs, address _caller) external pure returns (bytes32);
    function hashTakeBidSingle(TakeBidSingle memory inputs, address _caller) external pure returns (bytes32);
}