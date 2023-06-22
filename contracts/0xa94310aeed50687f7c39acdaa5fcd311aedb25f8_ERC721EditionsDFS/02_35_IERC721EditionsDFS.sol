// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../../royaltyManager/interfaces/IRoyaltyManager.sol";

/**
 * @notice Core creation interface
 * @author [email protected]
 */
interface IERC721EditionsDFS {
    /**
     * @notice Create an edition
     * @param _editionUri Edition uri (metadata)
     * @param _editionSize Edition size
     * @param _editionTokenManager Token manager for edition
     * @param editionRoyalty Edition's royalty
     */
    function createEdition(
        string memory _editionUri,
        uint256 _editionSize,
        address _editionTokenManager,
        IRoyaltyManager.Royalty memory editionRoyalty
    ) external returns (uint256);

    /**
     * @notice Get the first token minted for each edition passed in
     */
    function getEditionStartIds() external view returns (uint256[] memory);
}