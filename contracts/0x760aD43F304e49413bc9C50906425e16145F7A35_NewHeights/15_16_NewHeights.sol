// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {INewHeights} from "../interfaces/INewHeights.sol";

contract NewHeights is ERC721Enumerable, Ownable, INewHeights {
    using Counters for Counters.Counter;

    string public constant override DEFAULT_BASE_URI =
        "https://redemption-api.endstate.io/metadata/new-heights/";
    string public override baseURI;

    Counters.Counter internal _tokenIds;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        baseURI = DEFAULT_BASE_URI;
    }

    function mint(address to) external onlyOwner {
        _safeMint(to, _tokenIds.current());
        _tokenIds.increment();
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        return string.concat(DEFAULT_BASE_URI, Strings.toString(tokenId));
    }

    function withdrawFunds(address payable to, uint256 amount)
        external
        onlyOwner
    {
        require(
            amount <= address(this).balance,
            "NewHeights: insufficient funds"
        );
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "NewHeights: failed to send Ether");

        emit Withdrawn(to, amount);
    }

    receive() external payable {}
}