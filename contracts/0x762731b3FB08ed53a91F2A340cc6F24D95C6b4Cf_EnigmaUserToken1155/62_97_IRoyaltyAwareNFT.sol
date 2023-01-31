// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC2981.sol";

interface IRoyaltyAwareNFT is IERC2981 {
    /**
     * @notice Get the creator of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function getCreator(uint256 tokenId) external view virtual returns (address);

    /**
     * @notice Get the rights holder (the one to receive royalties) of given tokenID.
     * @param tokenId ID of the Token.
     * @return rights holder of given ID.
     */
    function rightsHolder(uint256 tokenId) external view virtual returns (address);

    /**
     * @notice Updates the rights holder for a specific tokenId
     * @param tokenId ID of the Token.
     * @param newRightsHolder new rights holderof given ID.
     * @dev Rights holder should only be set by the token creator
     */
    function setRightsHolder(uint256 tokenId, address newRightsHolder) external virtual;

    /**
     * @notice Kind of like an initializer for the upgrade where we support ERC2981
     */
    function declareERC2981Interface() external virtual;
}