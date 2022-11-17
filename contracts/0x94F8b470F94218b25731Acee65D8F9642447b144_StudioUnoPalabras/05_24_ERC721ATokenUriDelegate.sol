// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

import "./interfaces/ITokenUriDelegate.sol";

abstract contract ERC721ATokenUriDelegate is ERC721A, Ownable {
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
        if (!_exists(tokenId)) revert("ERC721A: invalid token ID");
        ITokenUriDelegate delegate = tokenUriDelegate_;
        if (address(delegate) == address(0)) return "";
        return delegate.tokenURI(tokenId);
    }
}