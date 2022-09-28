// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./ITokenUriDelegate.sol";

abstract contract ERC721TokenUriDelegate is ERC721, Ownable {
    ITokenUriDelegate private tokenUriDelegate_;

    function setTokenUriDelegate(ITokenUriDelegate delegate) public onlyOwner {
        tokenUriDelegate_ = delegate;
    }

    function tokenUriDelegate() public view returns (ITokenUriDelegate) {
        return tokenUriDelegate_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert("ERC721: invalid token ID");
        ITokenUriDelegate delegate = tokenUriDelegate_;
        if (address(delegate) == address(0)) return "";
        return delegate.tokenURI(tokenId);
    }
}