// SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BlockheadTweets is ERC721Enumerable, Ownable {
    mapping(uint256 => bool) private hasBeenMinted;
    uint256 maxTokens = 250;
    string ipfsHash;

    event TokenMinted(uint256 tokenId, address to);

    // constructor
    constructor() ERC721 ("Blockhead Tweets", "GOODGRIEF") {
        ipfsHash = "ipfs://Qmd7UFo7umGLscxbm7VHmFKCoLcjMLi1XyZ1rKVixBfYSY/";
    }
    
    // minting functionality
    function mintToken(uint256 tokenId) external payable {
        require(!hasBeenMinted[tokenId], "This token ID has already been minted.");
        require (tokenId >= 1 && tokenId <= 250, "Token ID is out of range.");
        require(totalSupply() < 250, "Minting is done.");
        require(msg.value == 0.5 ether, "Incorrect ETH transferred -- please send exactly 0.5 ETH.");
        payable(owner()).transfer(address(this).balance);
        hasBeenMinted[tokenId] = true;        
        _safeMint(msg.sender, tokenId);
        emit TokenMinted(tokenId, msg.sender);

    }
    
    function ownerMint(uint256 tokenId) external onlyOwner {
        require(!hasBeenMinted[tokenId], "This token ID has already been minted.");
        require (tokenId >= 1 && tokenId <= 250, "Token ID is out of range.");
        require(totalSupply() < 250, "Minting is done.");
        hasBeenMinted[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        emit TokenMinted(tokenId, msg.sender);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return ipfsHash;
    }

    function withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }
}