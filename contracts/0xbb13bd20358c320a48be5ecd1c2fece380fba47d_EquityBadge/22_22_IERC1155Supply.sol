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

import { IERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/**************************************

    IERC1155Supply interface

 **************************************/

/// @notice Supply extension to ERC1155 based on EIP5615.
interface IERC1155Supply is IERC1155Upgradeable {
    /// @dev Checks if token id exists.
    /// @param _id The token id to check the existence for
    /// @return True if token id exists
    function exists(uint256 _id) external view returns (bool);

    /// @dev Returns total number of minted tokens within token id.
    /// @param _id The token id for which the supply is returned
    /// @return Total supply of the given token id
    function totalSupply(uint256 _id) external view returns (uint256);
}