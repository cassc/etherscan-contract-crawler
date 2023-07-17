// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

import { BaseTypes } from "./BaseTypes.sol";

/// @notice Library that defines requests sent from frontend to smart contracts.
library RequestTypes {
    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Struct defining low level data for any request.
    /// @param sender Address of account executing tx
    /// @param expiry Deadline on which request expires
    /// @param nonce Number used only once used to prevent tx reply or out of order execution
    struct BaseRequest {
        address sender;
        uint256 expiry;
        uint256 nonce;
    }

    /// @dev Struct used to create a raise.
    /// @param raise Struct containing info about raise
    /// @param vested Struct containing info about vested ERC20
    /// @param base Struct defining low level data for a request
    struct CreateRaiseRequest {
        BaseTypes.Raise raise;
        BaseTypes.Vested vested;
        BaseRequest base;
    }

    /// @dev Struct used to set a token for an early stage raise.
    /// @param raiseId UUID of raise
    /// @param token Address of ERC20
    /// @param base Struct defining low level data for a request
    struct SetTokenRequest {
        string raiseId;
        address token;
        BaseRequest base;
    }

    /// @dev Struct used to invest into raise.
    /// @param raiseId UUID of raise
    /// @param investment Amount of base asset used to invest
    /// @param maxTicketSize Individual limit of investment for validation
    /// @param base Struct defining low level data for a request
    struct InvestRequest {
        string raiseId;
        uint256 investment;
        uint256 maxTicketSize;
        BaseRequest base;
    }

    /// @dev Struct used to unlock milestone
    /// @param raiseId UUID of raise
    /// @param milestone Index of inserted milestone
    /// @param share % of unlocked tokens
    /// @param base Struct defining low level data for a request
    struct UnlockMilestoneRequest {
        string raiseId;
        uint256 milestone;
        uint256 share;
        BaseRequest base;
    }

    /// @dev Struct used to claim a tokens from milestone
    /// @param raiseId UUID of raise
    /// @param recipients Group of investors or startup address
    /// @param base Struct defining low level data for a request
    struct ClaimMilestoneRequest {
        string raiseId;
        address[] recipients;
        BaseRequest base;
    }
}