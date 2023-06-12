// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC721Enumerable.sol";
import "./ERC721.sol";
import "../libraries/Errors.sol";

contract ERC721Enumerable is
    ERC721,
    IERC721Enumerable
{
    uint256 internal tokens;
    uint256 internal burnt;

    function totalSupply()
        external
        override
        view
        returns (uint256)
    {
        return tokens - burnt;
    }

    function mintedFrames()
        internal
        view
        returns(uint256)
    {
        return tokens;
    }

    function tokenByIndex(
        uint256 _index
    )
        external
        override
        view
        validNFToken(_index)
        returns (uint256)
    {
        return _index;
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        override
        view
        validNFToken(_index)
        returns (uint256)
    {
        require(_ownerOf(_index) == _owner, errors.NOT_OWNER);
        return _index;
    }

    function _mint(
        address _to,
        uint256 _tokenId
    )
        internal
        override
        virtual
    {
        super._mint(_to, _tokenId);
        tokens++;
    }

    function _burn(
        uint256 _tokenId
    )
        internal
        override
        virtual
    {
        super._burn(_tokenId);
        burnt++;
    }
}