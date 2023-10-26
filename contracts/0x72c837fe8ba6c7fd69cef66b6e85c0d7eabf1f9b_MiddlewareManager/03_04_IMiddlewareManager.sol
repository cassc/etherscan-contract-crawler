// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IMiddlewareManagerEvents } from "../interfaces/IMiddlewareManagerEvents.sol";

/**
 * @title IMiddlewareManager
 * @author CyberConnect
 */
interface IMiddlewareManager is IMiddlewareManagerEvents {
    /**
     * @notice Allows the middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowMw(address mw, bool allowed) external;

    /**
     * @notice Checks if the middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isMwAllowed(address mw) external view returns (bool);
}