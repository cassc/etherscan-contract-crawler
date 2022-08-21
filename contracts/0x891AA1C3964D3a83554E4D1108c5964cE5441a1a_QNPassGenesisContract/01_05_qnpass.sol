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

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract QNPassGenesisContract is ERC721A, Ownable {

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmount = 20;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    mapping(address => uint256) public whitelistUserAmount;
    
    constructor(
    ) ERC721A('QNPassGenesis', 'QPG') {
        setBaseURI('ipfs://QmfNVFBY9hFyTbT83UzJeCcmyEu1JiJpa261QJ3a6Qh4Je/');
        _safeMint(msg.sender, 1);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");

        if(onlyWhitelisted == true) {
            require(whitelistUserAmount[msg.sender] != 0, "user is not whitelisted");
            require(_mintAmount <= whitelistUserAmount[msg.sender], "max NFT per address exceeded");
        }

        //check end
        if(onlyWhitelisted == true) {
            whitelistUserAmount[msg.sender] -= _mintAmount;
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function setWhitelist(address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistUserAmount[addresses[i]] = saleSupplies[i];
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    //only owner  
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }    

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
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