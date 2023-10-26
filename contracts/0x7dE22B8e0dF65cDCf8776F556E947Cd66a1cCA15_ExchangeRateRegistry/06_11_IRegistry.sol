// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity ^0.8.0;

import {IBloomPool} from "./IBloomPool.sol";

/**
 * @title Bloom Registry interface to return exchangeRate
 */
interface IRegistry {
    /**
     * @notice Returns the current exchange rate of the given token
     * @param token The token address
     * @return The current exchange rate of the given token
     */
    function getExchangeRate(address token) external view returns (uint256);

    /**
     * @notice Register new token to the registry
     * @dev This is a permissioned function. Only the BloomFactory or the registry owner can call this function
     * @param token The TBY token that will be registered (aka the BloomPool)
     */
    function registerToken(IBloomPool token) external; 

}