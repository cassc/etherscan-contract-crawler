// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/** @title IFirstDibsRoyalties
 * @dev Interface for the ERC2981 Token Royalty standard, as well as the rarible schema
 */
interface IFirstDibsRoyalties {
    /**
     * @dev getter & setter for current creator royalty basis points
     */
    function globalCreatorRoyaltyBasisPoints() external view returns (uint32);
    function setGlobalCreatorRoyaltyBasisPoints(uint32 _royaltyRate) external;
    /**
     * @dev EIP-2981 royalty standard https://eips.ethereum.org/EIPS/eip-2981
     * @param _tokenId token ID to receive royalty info on
     * @param _value amount to calculate royalty for
     */
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}