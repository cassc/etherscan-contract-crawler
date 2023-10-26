// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title IMiddlewareManagerEvents
 * @author CyberConnect
 */
interface IMiddlewareManagerEvents {
    /**
     * @notice Emitted when a profile middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );
}