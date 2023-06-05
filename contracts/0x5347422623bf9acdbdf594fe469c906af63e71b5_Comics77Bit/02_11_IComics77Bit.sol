// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IComics77Bit is IERC1155 {
    
    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Emitted when a new metadata URI is set.
     *  @param uri_ The new metadata URI.
    */
    event UriSet(string uri_);

    /**
     *  @dev   Emitted when a new allowed minter is called.
     *  @param minter_ The address of the new minter.
     *  @param isValid_ Whether the new minter is valid.
    */
    event AllowedMinterSet(address indexed minter_, bool isValid_);

    /**
     *  @dev   Emitted when a new allowed burner is called.
     *  @param burner_ The address of the new burner.
     *  @param isValid_ Whether the new burner is valid.
    */
    event AllowedBurnerSet(address indexed burner_, bool isValid_);

    /******************************************************************************************************************************/
    /*** Administrative Functions                                                                                               ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Sets the metadata URI.
     *  @param uri_ The new metadata URI.
     */
    function setURI(string memory uri_) external;

    /**
     *  @dev   Sets a new minter as valid or not.
     *  @param minter_  The address of the new minter.
     *  @param isValid_ Whether the new minter is valid.
     */
    function setAllowedMinter(address minter_, bool isValid_) external;

    /**
     *  @dev   Sets a new burner as valid or not.
     *  @param burner_  The address of the new burner.
     *  @param isValid_ Whether the new burner is valid.
     */
    function setAllowedBurner(address burner_, bool isValid_) external;

    /******************************************************************************************************************************/
    /*** Minter Functions                                                                                                       ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Mints tokens.
     *  @param recipients_ The recipients of the minted assets.
     *  @param ids_ The types of assets to mint.
     *  @param amounts_ The amounts of assets to mint.
     */
    function mint(address[] memory recipients_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /**
     *  @dev   Mints token batches.
     *  @param recipients_ The recipients of the minted assets.
     *  @param ids_ The types of assets to mint per batch.
     *  @param amounts_ The amounts of assets to mint per batch.
     */
    function mintBatch(address[] memory recipients_, uint256[][] memory ids_, uint256[][] memory amounts_) external;

    /******************************************************************************************************************************/
    /*** Burner Functions                                                                                                       ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Burns tokens.
     *  @param account_ The owner of the burnt assets.
     *  @param ids_ The types of assets to burn.
     *  @param amounts_ The amounts of assets to burn.
     */
    function burn(address account_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /**
     *  @dev   Burns token batches.
     *  @param accounts_ The owners of the burnt assets.
     *  @param ids_ The types of assets to burn per batch.
     *  @param amounts_ The amounts of assets to burn per batch.
     */
    function burnBatch(address[] memory accounts_, uint256[][] memory ids_, uint256[][] memory amounts_) external;
}