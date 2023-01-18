// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC721A, ERC721A, ERC721AExtended, ERC721AMintable} from "./ERC721A/ERC721AExtended.sol";
import {ERC721Common, WithMeta, IERC2981, ERC2981} from "./ERC721Common.sol";

import {IBase721A} from "./IBase721A.sol";

/// @title Base721A
/// @author dev by @dievardump
/// @notice Contains both the common goodies and implementation specific extensions to ERC721A
contract Base721A is IBase721A, ERC721Common, ERC721AExtended {
    constructor(
        string memory name_,
        string memory ticker_,
        ERC721CommonConfig memory config
    ) ERC721A(name_, ticker_) ERC721Common(config) {}

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    /// @inheritdoc ERC721A
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721A
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return _tokenURI(tokenId);
    }

    /////////////////////////////////////////////////////////
    // Interactions                                        //
    /////////////////////////////////////////////////////////

    /// @inheritdoc ERC721A
    /// @dev overrode to add the FilterOperator
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721A
    /// @dev overrode to add the FilterOperator
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721A
    /// @dev overrode to add the FilterOperator
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @inheritdoc ERC721A
    /// @dev overrode to add the FilterOperator
    function setApprovalForAll(address operator, bool _approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorForApproval(operator, _approved)
    {
        super.setApprovalForAll(operator, _approved);
    }

    /////////////////////////////////////////////////////////
    // Gated Minted                                        //
    /////////////////////////////////////////////////////////

    /// @notice Allows a `minter` to mint `amount` tokens to `to` with `extraData_`
    /// @param to to whom we need to mint
    /// @param amount how many to mint
    function mintTo(
        address to,
        uint256 amount,
        uint24 extraData_
    ) public virtual onlyMinter {
        _mintTo(to, amount, extraData_);
    }

    /////////////////////////////////////////////////////////
    // Internals                                          //
    /////////////////////////////////////////////////////////

    function _baseURI() internal view virtual override(ERC721A, WithMeta) returns (string memory) {
        return WithMeta._baseURI();
    }
}