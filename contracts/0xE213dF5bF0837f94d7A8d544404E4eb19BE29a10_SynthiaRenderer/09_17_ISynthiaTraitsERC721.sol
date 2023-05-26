pragma solidity >=0.6.2 <0.9.0;

interface ISynthiaTraitsERC721 {
    /// @dev Function MUST return a valid index for the trait it represents
    function getTraitIndex(uint256 tokenId) external view returns (uint256);

    /// @dev Gets the custom name of the given trait item. This should not be confused with the trait name from ISynthiaErc721.
    /// The trait name from ISynthiaErc721 would be "head" where here it would be the name of the item place on the "head" such as "red hat".
    function getTraitName(uint256 tokenId) external view returns (string memory);

    /// @dev Function MUST return the base64 url for a give token ID which represents a trait
    function getTraitImage(uint256 tokenId) external view returns (string memory);
}