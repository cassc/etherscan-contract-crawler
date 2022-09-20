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

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Minter is Ownable {
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    function setMinter(address address_, bool bool_) external onlyOwner {
        minters[address_] = bool_;
    }
    function isMinter(address address_) internal view returns(bool) {
        return minters[address_];
    }
}

abstract contract Burner is Ownable {
    mapping(address => bool) public burners;
    modifier onlyBurner { require(burners[msg.sender], "Not Burner!"); _; }
    function setBurner(address address_, bool bool_) external onlyOwner {
        burners[address_] = bool_;
    }
    function isBurner(address address_) internal view returns(bool) {
        return burners[address_];
    }
}

//on chain metadata interface
interface iOCM {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface iNFTCollection {
    function balanceOf(address _address) external view returns (uint256);
}


contract NekoGeneContract is ERC721A, Ownable, Minter, Burner {

    iOCM public OCM;
    iNFTCollection public NFT1;
    iNFTCollection public NFT2;
    iNFTCollection public NFT3;
    iNFTCollection public NFT4;

    bool public useOnChainMetadata = false;


    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0;
    uint256 public maxSupply = 860;
    uint256 public maxMintAmount = 3;
    bool public paused = true;

    mapping(address => uint256) public whitelistMintedAmount;
    address public constant withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    constructor(
    ) ERC721A("NekoGeneMillennium", "NGM") {
        setBaseURI("ipfs://QmdzJxpJSRFucsHh5v9TUZW1GCdogBz9iuqg3Q6HVE6Nvz/");
        //honban kore ha nokosu
        NFT1 = iNFTCollection(0x845a007D9f283614f403A24E3eB3455f720559ca);//cnp
        NFT2 = iNFTCollection(0xFE5A28F19934851695783a0C8CCb25d678bB05D3);//cnpj
        NFT3 = iNFTCollection(0xCFE50e49ec3E5eb24cc5bBcE524166424563dD4E);//vlcnp
        NFT4 = iNFTCollection(0xcaE19776cB7197676F9b15f1DA6D110DdDFB181C);//pix-nin
        _safeMint(0xdEcf4B112d4120B6998e5020a6B4819E490F7db6, 1);
    }

    //modifier
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract.');
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    // public
    function mint(uint256 _mintAmount ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");
        require(isWhitelisted(msg.sender) == true , "You are not whitelisted" );

        _safeMint(msg.sender, _mintAmount);
    }

    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(0 < _mintAmount , "need to mint at least 1 NFT");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useOnChainMetadata) {
            return OCM.tokenURI(tokenId);
        } else {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
        }
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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function isWhitelisted(address _address) public view returns(bool){
        if( 0 < NFT1.balanceOf(_address) ) {
            return true;
        }
        if( 0 < NFT2.balanceOf(_address) ) {
            return true;
        }
        if( 0 < NFT3.balanceOf(_address) ) {
            return true;
        }
        if( 0 < NFT4.balanceOf(_address) ) {
            return true;
        }
        return false;
    }

    //only burner or minter
    function externalMint(address _address , uint256 _amount ) external payable onlyMinter{
        require( _nextTokenId() -1 + _amount <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }

    function externalBurn(address _address, uint256[] memory _burnTokenIds) external onlyBurner{
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(_address == ownerOf(tokenId) , "Owner is different");

            _burn(tokenId);
        }        
    }

    //only owner
    function setNFTCollection(address _address1, address _address2 , address _address3 , address _address4) public onlyOwner(){
        NFT1 = iNFTCollection(_address1);
        NFT2 = iNFTCollection(_address2);
        NFT3 = iNFTCollection(_address3);
        NFT4 = iNFTCollection(_address4);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
        maxSupply = _maxSupply;
    }

    function setOCM(address _address) public onlyOwner() {
        OCM = iOCM(_address);
    }

    function setUseOnChainMetadata(bool _useOnChainMetadata) public onlyOwner() {
        useOnChainMetadata = _useOnChainMetadata;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
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
 
    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


}