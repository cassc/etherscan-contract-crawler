pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ShibaSociety is ERC721("Shiba Society", "SHIBS"), Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    string[] baseURI;
    string blindURI1_;
    string blindURI2_;

    uint256 public totalSupply;
    uint256 public BUY_LIMIT_PER_TX = 10;
    uint256 public MAX_NFT = 10000;

    uint256 public constant NFTPrice = 35000000000000000; // 0.035 ETH

    constructor() {}

    /*
     * Function to withdraw collected amount during minting
    */
    function withdraw(address _to) public onlyOwner {
        uint balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    /*
     * Function to mint new NFTs
     * It is payable. Amount is calculated as per (NFTPrice*_numOfTokens)
    */
    function mintNFT(uint256 _numOfTokens) public payable whenNotPaused {
        require(_numOfTokens <= BUY_LIMIT_PER_TX, "Can't mint above limit");
        require(totalSupply.add(_numOfTokens) <= MAX_NFT, "Purchase would exceed max supply of NFTs");
        require(NFTPrice.mul(_numOfTokens) == msg.value, "Ether value sent is not correct");

        for(uint i=0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply);
            totalSupply = totalSupply.add(1);
        }
    }

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (tokenId < 1000) {
            return bytes(baseURI[0]).length > 0 && totalSupply >= 1000 ? string(abi.encodePacked(baseURI[0], 
                tokenId.toString())) : string(abi.encodePacked(blindURI1_, tokenId.toString()));
        } else if (tokenId >= 1000 && tokenId < 2000) {
            return bytes(baseURI[1]).length > 0 && totalSupply >= 2000 ? string(abi.encodePacked(baseURI[1], 
                tokenId.toString())) : string(abi.encodePacked(blindURI1_, tokenId.toString()));
        } else if (tokenId >= 2000 && tokenId < 3000) {
            return bytes(baseURI[2]).length > 0 && totalSupply >= 3000 ? string(abi.encodePacked(baseURI[2], 
                tokenId.toString())) : string(abi.encodePacked(blindURI1_, tokenId.toString()));
        } else if (tokenId >= 3000 && tokenId < 4000) {
            return bytes(baseURI[3]).length > 0 && totalSupply >= 4000 ? string(abi.encodePacked(baseURI[3], 
                tokenId.toString())) : string(abi.encodePacked(blindURI1_, tokenId.toString()));
        } else if (tokenId >= 4000 && tokenId < 5000) {
            return bytes(baseURI[4]).length > 0 && totalSupply >= 5000 ? string(abi.encodePacked(baseURI[4], 
                tokenId.toString())) : string(abi.encodePacked(blindURI1_, tokenId.toString()));
        } else if (tokenId >= 5000 && tokenId < 6000) {
            return bytes(baseURI[5]).length > 0 && totalSupply >= 6000 ? string(abi.encodePacked(baseURI[5], 
                tokenId.toString())) : string(abi.encodePacked(blindURI2_, tokenId.toString()));
        } else if (tokenId >= 6000 && tokenId < 7000) {
            return bytes(baseURI[6]).length > 0 && totalSupply >= 7000 ? string(abi.encodePacked(baseURI[6], 
                tokenId.toString())) : string(abi.encodePacked(blindURI2_, tokenId.toString()));
        } else if (tokenId >= 7000 && tokenId < 8000) {
            return bytes(baseURI[7]).length > 0 && totalSupply >= 8000 ? string(abi.encodePacked(baseURI[7], 
                tokenId.toString())) : string(abi.encodePacked(blindURI2_, tokenId.toString()));
        } else if (tokenId >= 8000 && tokenId < 9000) {
            return bytes(baseURI[8]).length > 0 && totalSupply >= 9000 ? string(abi.encodePacked(baseURI[8], 
                tokenId.toString())) : string(abi.encodePacked(blindURI2_, tokenId.toString()));
        } else {
            return bytes(baseURI[9]).length > 0 && totalSupply >= MAX_NFT ? string(abi.encodePacked(baseURI[9], 
                tokenId.toString())) : string(abi.encodePacked(blindURI2_, tokenId.toString()));
        }
    }

    /*
     * Function to set Base and Blind URI 
    */
    function setURIs(string memory _blindURI1, string memory _blindURI2, string[] memory _URIs) external onlyOwner {
        require(_URIs.length == 10, "10 URI required");
        blindURI1_ = _blindURI1;
        blindURI2_ = _blindURI2;
        baseURI = _URIs;
    }

    /*
     * Function to pause 
    */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * Function to unpause 
    */
    function unpause() external onlyOwner {
        _unpause();
    }
}