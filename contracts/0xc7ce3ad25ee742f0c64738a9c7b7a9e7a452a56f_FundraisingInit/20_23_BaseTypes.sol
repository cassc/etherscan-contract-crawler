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

/// @notice Library with core types definition.
library BaseTypes {
    // -----------------------------------------------------------------------
    //                              Enums
    // -----------------------------------------------------------------------

    /// @dev Definition of base asset for investment.
    enum Asset {
        USDT,
        AZERO
    }

    /// @dev Definition of supported types of raises.
    enum RaiseType {
        Standard,
        EarlyStage
    }

    // -----------------------------------------------------------------------
    //                              Enums
    // -----------------------------------------------------------------------

    /// @dev Struct containing price information.
    /// @param tokensPerBaseAsset Ratio of how much tokens is worth 1 unit of base asset (vested * precision / hardcap)
    /// @param asset Supported base asset for investment
    struct Price {
        uint256 tokensPerBaseAsset;
        Asset asset;
    }

    /// @dev Struct containing detailed info about raise.
    /// @param price Struct containing price information
    /// @param hardcap Max amount of base asset to collect during a raise
    /// @param softcap Min amount of base asset to collect during a raise
    /// @param start Start date of raise
    /// @param end End date of raise
    /// @param badgeUri IPFS URI that initializes equity badge for the raise
    struct RaiseDetails {
        Price price;
        uint256 hardcap;
        uint256 softcap;
        uint256 start;
        uint256 end;
        string badgeUri;
    }

    /// @dev Struct containing all information about the raise.
    /// @param raiseId UUID of raise
    /// @param raiseType Type of raise
    /// @param raiseDetails Struct containing detailed info about raise
    /// @param owner Address of startup
    struct Raise {
        string raiseId;
        RaiseType raiseType;
        RaiseDetails raiseDetails;
        address owner;
    }

    /// @dev Struct containing info about vested token accredited for investing.
    /// @param erc20 Address of vested token
    /// @param amount Amount of vested ERC20
    struct Vested {
        address erc20;
        uint256 amount;
    }
}