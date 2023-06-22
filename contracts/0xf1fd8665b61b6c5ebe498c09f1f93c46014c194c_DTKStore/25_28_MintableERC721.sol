// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

contract MintableERC721 is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // for mint control
    Counters.Counter private supply;
    Counters.Counter private minted; // for micmicking thirdweb droperc721
    uint256 public maxSupply;

    string baseUri;
    string contractURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        string memory contractURI_,
        uint256 maxSupply_
    ) ERC721(name_, symbol_) {
        baseUri = baseUri_;
        contractURI = contractURI_;
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function totalMinted() public view returns (uint256) {
        return minted.current();
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function mint() public {
        require(supply.current() < maxSupply);
        super._safeMint(_msgSender(), supply.current());
        supply.increment();
    }
}