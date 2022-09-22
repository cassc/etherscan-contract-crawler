//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SlicesOfNFTs is ERC721, Ownable {
    uint256 public totalSupply;
    uint256 public maxSupply;
    string public baseURI = "https://metadata.slicesofnfts.com/";
    string public constant baseExtension = ".json";


    constructor() ERC721('SlicesOfNFTs', 'SON') {
      maxSupply = 365;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
      maxSupply = maxSupply_;
    }

    function artistMint(address _to) external onlyOwner {
        require(maxSupply > totalSupply, 'Enough collections have been sliced up');
        uint256 tokenId = totalSupply;
        totalSupply++;
        mint(_to, tokenId);
    }

    function mint(address _addr, uint256 _tokenId) internal {
        _safeMint(_addr, _tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
}