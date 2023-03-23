// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IBrandNFT {
    /// @notice Return the address of the minting contract
    function brandCentral() external view returns (address);

    /// @notice Utility for converting string to lowercase equivalent
    function toLowerCase(string memory _base) external pure returns (string memory);

    /// @notice Get the token ID from a brand ticker
    function lowercaseBrandTickerToTokenId(string memory _ticker) external view returns (uint256);

    /// @notice Allow a brand owner to set their image and description which will surface in NFT explorers
    function setBrandMetadata(uint256 _tokenId, string calldata _description, string calldata _imageURI) external;

    /// @notice Vanilla ERC721 transfer function
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}