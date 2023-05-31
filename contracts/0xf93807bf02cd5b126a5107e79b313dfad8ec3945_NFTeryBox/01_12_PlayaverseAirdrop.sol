//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTeryBox is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed;

    constructor() ERC721A("NFTeryBox", "NFTB") {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmY7CTbiRaH8tXugTgRdc887YjsDoc6tsb26vSvyqhVYka");
        _safeMint(msg.sender, 1);
    }

    //SETTERS

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //END SETTERS

    //MINT FUNCTIONS

    function airdrop(address to, uint256 amount) external onlyOwner {
        _safeMint(to, amount);
    }

    function airdropMultiple(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function airdropBatch(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            addresses.length == amounts.length,
            "Addresses and mounts length do not match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function forceMint(uint256 amount) public onlyOwner {
        _safeMint(msg.sender, amount);
    }

    // END MINT FUNCTIONS

    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }
}