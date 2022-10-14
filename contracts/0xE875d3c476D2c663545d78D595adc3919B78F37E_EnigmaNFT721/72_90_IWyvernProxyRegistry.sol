// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title IWyvernProxyRegistry
 * @author Wyvern Protocol Developers
 */
interface IWyvernProxyRegistry {
    /**
     * Returns The Wyvern Proxy for the given owner
     * @param owner the owner of the Proxy
     * @dev based on Apr '22 https://github.com/wyvernprotocol/wyvern-v3
     */
    function proxies(address owner) external view returns (address);
}