// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@7i7o/tokengate/src/ERC721TGNT.sol";
import {TokenURIDescriptor} from "./lib/TokenURIDescriptor.sol";

contract SVGie is ERC721TGNT {
    address public owner;
    uint256 public totalSupply;
    uint256 public price;
    bool public mintActive;

    error NotOwnerOf(uint256 tokenId);

    error OnlyOwner();

    constructor(uint256 mintPrice) ERC721TGNT("SVGie", "SVGie") {
        owner = msg.sender;
        price = mintPrice;
    }

    function safeMint(address _to) public payable {
        require(mintActive, "Mint is not active");
        require(msg.value >= price, "Value sent < Mint Price");
        totalSupply++;
        _safeMint(_to, uint256(uint160(_to)));
    }

    function teamMint(address _to) public {
        if (msg.sender != owner) revert OnlyOwner();
        totalSupply++;
        _safeMint(_to, uint256(uint160(_to)));
    }

    function burn(uint256 tokenId) public virtual {
        if (msg.sender != ownerOf(tokenId)) revert NotOwnerOf(tokenId);
        totalSupply--;
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721TGNT)
        returns (string memory)
    {
        require(_exists(tokenId), "SVGie: Non Existent TokenId");
        return
            TokenURIDescriptor.tokenURI(
                address(uint160(tokenId)),
                super.name(),
                super.symbol()
            );
    }

    function setOwner(address newOwner) public {
        if (msg.sender != owner) revert OnlyOwner();
        owner = newOwner;
    }

    function setPrice(uint256 mintPrice) public {
        if (msg.sender != owner) revert OnlyOwner();
        price = mintPrice;
    }

    function toggleMintActive() public {
        if (msg.sender != owner) revert OnlyOwner();
        if (!mintActive) mintActive = true;
        else mintActive = false;
    }

    function withdraw() public {
        uint256 amount = address(this).balance;
        // Revert if no funds
        require(amount > 0, "Balance is 0");
        // Withdraw funds.
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Withdraw failed");
    }
}