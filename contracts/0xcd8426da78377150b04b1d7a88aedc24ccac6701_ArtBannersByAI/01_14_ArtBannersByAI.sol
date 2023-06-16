// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14 <0.9.0;

import "./IAINightbirds.sol";
import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract ArtBannersByAI is ERC721Optimized, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_ABBA = 10000;
    string public _baseABBAURI;

    IAINightbirds public immutable ainightbirds;
    
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(IAINightbirds _ainightbirds, string memory baseURI) ERC721Optimized("ArtBannersByAI", "ABBA") {
        ainightbirds = _ainightbirds;
        _baseABBAURI = baseURI;
    }

    function drop(uint256 numberOfTokens) public onlyOwner {
        uint256 tokenId = totalSupply();
        uint256 end = Math.min(tokenId + numberOfTokens, MAX_ABBA);

        IAINightbirds ainb = ainightbirds;
        for (; tokenId < end; ++tokenId) {
            _mint(ainb.ownerOf(tokenId), tokenId);
        }
    }

    function dropToAddress(address to) public onlyOwner {
        _mint(to, totalSupply());
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _baseABBAURI = newuri;
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "Caller is not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function _baseURI() internal view virtual returns (string memory) {
	    return _baseABBAURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Token does not exist");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
}