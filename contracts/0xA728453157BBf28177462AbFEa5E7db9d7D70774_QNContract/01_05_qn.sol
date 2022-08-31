// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Keisuke OHNO

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;

interface iOCM {
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract QNContract is ERC721A, Ownable {

    iOCM public OCM;
    bool public useOnChainMetadata = false;
    string baseURI;
    uint256 public maxSupply = 0;
    string public baseExtension = ".json";
    
    constructor(
    ) ERC721A('QN', 'QN') {
        setBaseURI('ipfs://QmYoiSzanBnqYuf8CUK4d4ZfLiLNjcdDQ6HJfncJdLTBD9/');
        mint(5);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    //public
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useOnChainMetadata) {
            return OCM.tokenURI(tokenId);
        } else {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
        }
    }

    //only owner  
    function mint(uint256 _mintAmount) public onlyOwner {
        maxSupply += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function setOCM(address _address) public onlyOwner() {
        OCM = iOCM(_address);
    }

    function setUseOnChainMetadata(bool _useOnChainMetadata) public onlyOwner() {
        useOnChainMetadata = _useOnChainMetadata;
    }
  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function walletOfOwner(address _address) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_address);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _address) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

}