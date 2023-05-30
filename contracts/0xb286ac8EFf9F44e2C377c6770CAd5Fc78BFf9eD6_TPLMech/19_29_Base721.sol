// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC721, ERC721, ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Common, WithMeta, ERC2981} from "./ERC721Common.sol";

/// @title Base721
/// @author dev by @dievardump
/// @notice ERC721 base with Burnable and common stuff for all 721 implementations
contract Base721 is ERC721Common, ERC721Burnable {
    error TooManyRequested();
    error InvalidZeroMint();

    uint256 internal _lastTokenId;

    constructor(
        string memory name_,
        string memory ticker_,
        ERC721CommonConfig memory config
    ) ERC721(name_, ticker_) ERC721Common(config) {}

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return _tokenURI(tokenId);
    }

    /////////////////////////////////////////////////////////
    // Interactions                                        //
    /////////////////////////////////////////////////////////

    /// @inheritdoc ERC721
    /// @dev overrode to add the FilterOperator
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721
    /// @dev overrode to add the FilterOperator
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721
    /// @dev overrode to add the FilterOperator
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @inheritdoc ERC721
    /// @dev overrode to add the FilterOperator
    function setApprovalForAll(address operator, bool _approved)
        public
        override
        onlyAllowedOperatorForApproval(operator, _approved)
    {
        super.setApprovalForAll(operator, _approved);
    }

    /// @notice Allows any "minter" to mint `amount` new tokens to `to`
    /// @param to to whom we need to mint
    /// @param amount how many to mint
    function mintTo(address to, uint256 amount) external virtual onlyMinter {
        _mintTo(to, amount);
    }

    /////////////////////////////////////////////////////////
    // Internals                                          //
    /////////////////////////////////////////////////////////

    function _baseURI() internal view virtual override(ERC721, WithMeta) returns (string memory) {
        return WithMeta._baseURI();
    }

    /// @dev mints `amount` tokens to `to`
    /// @param to to whom we need to mint
    /// @param amount how many to mint
    function _mintTo(address to, uint256 amount) internal virtual returns (uint256) {
        if (amount == 0) {
            revert InvalidZeroMint();
        }
        uint256 maxSupply = _maxSupply();
        uint256 lastTokenId = _lastTokenId;

        // check that there is enough supply
        if (maxSupply != 0 && lastTokenId + amount > maxSupply) {
            revert TooManyRequested();
        }

        do {
            unchecked {
                amount--;
                ++lastTokenId;
            }
            _mint(to, lastTokenId);
        } while (amount > 0);

        _lastTokenId = lastTokenId;
        return lastTokenId;
    }

    /// @dev internal config to return the max supply and stop the mint function to work after it's met
    /// @return the max supply, 0 means no max
    function _maxSupply() internal view virtual returns (uint256) {
        return 0;
    }
}