// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Core creation interface
 * @author [email protected]
 */
interface IERC721Editions {
    /**
     * @dev Create an edition
     * @param _editionInfo Encoded edition metadata
     * @param _editionSize Edition size
     * @param _editionTokenManager Token manager for edition
     */
    function createEdition(
        bytes memory _editionInfo,
        uint256 _editionSize,
        address _editionTokenManager
    ) external returns (uint256);

    /**
     * @dev Get the first token minted for each edition passed in
     */
    function getEditionStartIds() external view returns (uint256[] memory);
}