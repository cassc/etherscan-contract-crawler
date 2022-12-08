// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
import "./ERC721P.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721Enum is ERC721P, IERC721Enumerable {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721P)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256 tokenId)
    {
        require(index < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
        uint256 count;
        for (uint256 i; i < _owners.length; ++i) {
            if (owner == _owners[i]) {
                if (count == index) return i;
                else ++count;
            }
        }
        require(false, "ERC721Enum: owner ioob");
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        require(0 < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < ERC721Enum.totalSupply(), "ERC721Enum: global ioob");
        return index;
    }
}
