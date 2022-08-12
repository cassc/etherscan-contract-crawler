// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ERC721Upgradeable } from "../../../deps/ERC721Upgradeable.sol";

/**
 * @title ERC721SequentialUpgradeable
 * @author Cyborg Labs, LLC
 *
 * @dev Base contract for an ERC-721 that is minted sequentially. Supports totalSupply().
 */
abstract contract ERC721SequentialUpgradeable is
    ERC721Upgradeable
{
    //---------------- Storage ----------------//

    uint256 internal _NEXT_TOKEN_ID_;

    uint256 internal _BURNED_COUNT_;

    uint256[48] private __gap;

    //---------------- Initializers ----------------//

    function __ERC721Sequential_init(
        string memory name,
        string memory symbol
    )
        internal
        onlyInitializing
    {
        __ERC721_init(name, symbol);
    }

    function __ERC721Sequential_init_unchained()
        internal
        onlyInitializing
    {}

    //---------------- Public Functions ----------------//

    function getNextTokenId()
        public
        view
        returns (uint256)
    {
        return _NEXT_TOKEN_ID_;
    }

    function getBurnedCount()
        public
        view
        returns (uint256)
    {
        return _BURNED_COUNT_;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _NEXT_TOKEN_ID_ - _BURNED_COUNT_;
    }

    //---------------- Internal Functions ----------------//

    function _mint(
        address recipient
    )
        internal
        returns (uint256)
    {
        uint256 tokenId = _NEXT_TOKEN_ID_++;
        ERC721Upgradeable._mint(recipient, tokenId);
        return tokenId;
    }

    function _burn(
        uint256 tokenId
    )
        internal
        override
    {
        _BURNED_COUNT_++;
        ERC721Upgradeable._burn(tokenId);
    }
}