// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./ERC721Upgradeable.sol";

/// @title ChecksElementsV2 ERC721 token contract
/// @author Visualize Value
contract ChecksElementsV2 is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    address private constant VV = 0xc8f8e2F59Dd95fF67c3d39109ecA2e2A017D4c8a;

    /// @dev Stores the base URI for token metadata
    string private baseURI;

    /// @notice Initializes the contract with the ERC721 token name and symbol, and sets the owner
    function initialize() public initializer {
        __ERC721_init("ChecksElements", "Elements");
        __Ownable_init();
    }

    /// @notice Premits all tokens to VV
    function premint () external onlyOwner {
        _premint(152, VV);
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