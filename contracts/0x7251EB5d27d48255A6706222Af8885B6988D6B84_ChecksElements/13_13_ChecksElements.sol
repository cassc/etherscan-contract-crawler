// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @title ChecksElements ERC721 token contract
/// @author Visualize Value
contract ChecksElements is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    /// @dev Stores the base URI for token metadata
    string private baseURI;

    /// @notice Initializes the contract with the ERC721 token name and symbol, and sets the owner
    function initialize() public initializer {
        __ERC721_init("ChecksElements", "Elements");
        __Ownable_init();
    }

    /// @notice Mints a new ERC721 token with the given tokenId
    /// @param to The address to mint the token to
    /// @param tokenId The unique identifier for the new token
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    /// @notice Sets the base URI for token metadata
    /// @param _baseURI The new base URI
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Returns the token URI for the specified tokenId
    /// @dev Overrides the tokenURI function of ERC721Upgradeable to use the custom baseURI
    /// @param tokenId The unique identifier of the token
    /// @return The token URI for the specified tokenId
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        return string(abi.encodePacked(baseURI, '/', tokenId.toString(), '/metadata.json'));
    }

    /// @dev A reserved space in storage to allow for future upgrades
    uint256[50] private __gap;
}