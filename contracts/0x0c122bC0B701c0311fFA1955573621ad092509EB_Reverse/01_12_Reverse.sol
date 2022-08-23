//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Reverse is ERC721A, Ownable {
    // ====== Variables ======
    string private baseURI;
    uint256 private MAX_SUPPLY = 870;

    constructor() ERC721A("ReverseDao Vesting NFT", "REVDNFT") {
    }

    // ====== Basic Setup ======
    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

     function setSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    // ====== Minting ======
    function ownerMint (uint256 _quantity) external payable onlyOwner {
        // *** Checking conditions ***
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reach maximum supply.");
        
        // *** _safeMint's second argument now takes in a quality but not tokenID ***
        _safeMint(msg.sender, _quantity);
    }

    // ====== Token URI ======
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token ID is not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    // ====== Withdraw ======
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw fail.");
    }
}