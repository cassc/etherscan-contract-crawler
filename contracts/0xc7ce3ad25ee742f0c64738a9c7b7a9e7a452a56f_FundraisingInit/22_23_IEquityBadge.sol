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

    EquityBadge interface

 **************************************/

/// @notice Equity badge interface
interface IEquityBadge is IERC1155Upgradeable {
    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error BadgeTransferNotYetPossible(); // 0xab99d45e
    error InvalidURI(uint256 badgeId); // 0x2e0740e9

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev Mint amount of ERC1155 badges to given user account.
    /// @param _sender Address of badge recipient
    /// @param _badgeId Number of badge (derived from project uuid)
    /// @param _amount Quantity of badges to mint
    /// @param _data Additional data for transfer hooks
    function mint(address _sender, uint256 _badgeId, uint256 _amount, bytes memory _data) external;

    /// @dev Set URI for badge id.
    /// @param _badgeId Id of badge
    /// @param _uri IPFS uri to JSON depicting badge
    function setURI(uint256 _badgeId, string memory _uri) external;
}