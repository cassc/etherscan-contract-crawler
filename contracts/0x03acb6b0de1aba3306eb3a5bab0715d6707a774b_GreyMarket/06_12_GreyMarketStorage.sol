// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GreyMarketData.sol";

/**
 * @title gm.co Storage
 * @author projectPXN
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarketStorage {
    address public proofSigner;
    mapping(bytes32 => bool) public orders;
}