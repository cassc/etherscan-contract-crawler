// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseCollectionETHDenver.sol";

/**
 * @title GinaBeaversETHDenver
 * @author @vtleonardo, @z-j-lin
 */
contract GinaBeaversETHDenver is BaseCollectionETHDenver {
    using Strings for uint256;

    uint256 public tokenOffset;

    constructor(
        string memory name_,
        string memory symbol_,
        address coaProxy_,
        address artist_,
        uint256 tokenOffset_
    ) BaseCollectionETHDenver(name_, symbol_, 500, 5, 0.36 ether, coaProxy_, artist_) {
        tokenOffset = tokenOffset_;
    }

    function setTokenOffset(uint256 tokenOffset_) public onlyOwner {
        tokenOffset = tokenOffset_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory tokenBaseURI = baseURI;
        return
            bytes(tokenBaseURI).length > 0
                ? string(abi.encodePacked(tokenBaseURI, (tokenId + tokenOffset).toString()))
                : "";
    }
}