// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Owned } from "solmate/src/auth/Owned.sol";

import { IMiddlewareManager } from "../interfaces/IMiddlewareManager.sol";

/**
 * @title MiddlewareManager
 * @author CyberConnect
 * @notice This contract manages middleware whitelist.
 * Only allowed middleware can be used in CyberConnect Protocol.
 */
contract MiddlewareManager is Owned, IMiddlewareManager {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) internal _mwAllowlist;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner) Owned(owner) {}

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMiddlewareManager
    function allowMw(address mw, bool allowed) external override onlyOwner {
        bool preAllowed = _mwAllowlist[mw];
        _mwAllowlist[mw] = allowed;

        emit AllowMw(mw, preAllowed, allowed);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMiddlewareManager
    function isMwAllowed(address mw) external view override returns (bool) {
        return _mwAllowlist[mw];
    }
}