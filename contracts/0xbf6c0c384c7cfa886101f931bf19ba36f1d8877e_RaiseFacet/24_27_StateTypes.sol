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

/// @notice Library that defines state related data.
library StateTypes {
    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Struct containing info about project state and investment data.
    /// @param raised Amount of raised base asset for fundraising
    /// @param invested Mapping that stores how much given address invested
    /// @param investmentRefunded Mapping that tracks if user was refunded
    /// @param collateralRefunded Boolean describing if startup was refunded
    /// @param reclaimed Boolean that shows if startup reclaimed unsold tokens
    struct ProjectInvestInfo {
        uint256 raised;
        mapping(address => uint256) invested;
        mapping(address => bool) investmentRefunded;
        bool collateralRefunded;
        bool reclaimed;
    }
}