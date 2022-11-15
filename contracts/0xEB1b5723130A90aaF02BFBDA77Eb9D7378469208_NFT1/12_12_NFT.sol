// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT1 is ERC721, Ownable {
    uint256 internal tokenId_;
    string internal baseURI_ = "https://ipfs.io/ipfs/";
    string internal tokenURI_ = "Qmd2nYWcq6YQZTiEmYneRVHNSYi5SpdvjqrWGkqihSMct8";
    string private certURI_ = "QmZxe3rLk8gNLy9x4D8116RkkqgAqogwhTiXwTPBtCHpaj?filename=certificate.jpg";

    event SetBaseURI(string newBaseURI);
    event SetTokenURI(string newTokenURI);
    event SetCertURI(string newCertURI);
    event Mint(address to, uint256 tokenId);

    constructor(string memory _name, string memory _symbol, address _ownerNFT) ERC721(_name, _symbol) {
        _mintTokens(_ownerNFT);
    }

    function _mintTokens(address _to) private {
        tokenId_ += 1;
        _mint(_to, tokenId_);
        emit Mint(_to, tokenId_);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return
            bytes(baseURI_).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI_,
                        tokenURI_
                    )
                )
                : "";
    
    }

    function getCertificate() public view returns (string memory) {
        return 
            bytes(baseURI_).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI_,
                        certURI_
                    )
                )
                : "";
    }

    function setTokenURI(string memory _newTokenURI) external onlyOwner {
        tokenURI_ = _newTokenURI;
        emit SetTokenURI(tokenURI_);
    }

    function setCertURI(string memory _newCertURI) external onlyOwner {
        certURI_ = _newCertURI;
        emit SetCertURI(certURI_);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI_ = _newBaseURI;
        emit SetBaseURI(_newBaseURI);
    }
}