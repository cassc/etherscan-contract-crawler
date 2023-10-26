// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFractonXERC721.sol";

contract FractonXERC721 is IFractonXERC721, ERC721, Ownable {

    uint256 public tokenId;
    uint256 public totalSupply;
    string private uri;

    event EventSetTokenURI(string);

    constructor(string memory name_, string memory symbol_, string memory tokenUri) ERC721(name_, symbol_) {
        uri = tokenUri;
    }

    function mint(address to) external onlyOwner returns(uint256 curTokenId){
        curTokenId = tokenId;
        _safeMint(to, tokenId);
        tokenId += 1;
        totalSupply += 1;
    }

    function burn(uint256 tokenid) external onlyOwner {
        _burn(tokenid);
        totalSupply -= 1;
    }

    function setTokenURI(string calldata tokenuri) external onlyOwner {
        uri = tokenuri;
        emit EventSetTokenURI(tokenuri);
    }

    function tokenURI(uint256 ) public view  override returns (string memory) {
        return uri;
    }
}