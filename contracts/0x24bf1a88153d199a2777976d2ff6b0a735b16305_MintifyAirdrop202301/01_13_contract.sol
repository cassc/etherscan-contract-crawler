//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintifyAirdrop202301 is ERC721, ERC721Burnable, Ownable {
    uint256 tokenCount = 1;
    uint256 burnedTokens = 0;
    string private baseURI = "https://ipfs.io/ipfs/QmZvBcZgEDf85WDwR7cX6EwP1znstsafq3KZuK87UpG8Yy";


    // Constructor
    constructor() ERC721("Mintify Whale Airdrop", "MNTFYAD202301") {

    }

    // Mint
    function airDrop(address[] memory accounts) public onlyOwner {
        for (uint i=0; i < accounts.length; i++) {
            _safeMint(accounts[i], tokenCount);
            tokenCount++;
        }
    }

    // Burn
    function burn(uint256 tokenId) public virtual override(ERC721Burnable) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
        burnedTokens++;
    }

    // Sets BaseURI
    function setBaseURI(string calldata _baseURI ) public onlyOwner {
        baseURI = _baseURI;
    }

    // Gets total supply
    function totalSupply() public view returns(uint) {
        return tokenCount - 1 - burnedTokens;
    }

    // Withdraw Balance to Address
    function withdraw(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    // Gets token URI
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

}