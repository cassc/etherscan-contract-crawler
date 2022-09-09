// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HdlLogo is ERC721, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("HdlLogo", "HDL") {}       

    uint256 public maxSupply = 5000;
    bool public isMintActive = false;
    mapping(address => bool) _hasMinted;
    string private _baseTokenURI =
        "ipfs://bafybeih5aylmrja5iilebwdeuhi4zcc4veyfr4yxgmvr2rmandate3muri/";   

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function toggleMint() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function checkHasMinted(address _address) external view returns (bool) {
        return _hasMinted[_address];
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function safeMint() external {
        uint256 tokenId = _tokenIdCounter.current();

        require(isMintActive, "Minting is not active");
        require(tokenId < maxSupply, "All NFTs have been minted");
        require(!_hasMinted[msg.sender], "You have already minted an NFT");

        _tokenIdCounter.increment();
        _hasMinted[msg.sender] = true;

        _safeMint(msg.sender, tokenId);
    }
}