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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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


contract SanuQNContract is ERC721A, Ownable, Minter, Burner {

    iOCM public OCM;
    bool public useOnChainMetadata = false;


    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 1000000000000000;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 200;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    bool public preSale = true; //true = pre sale  ; false = public sale

    mapping(address => uint256) public whitelistMintedAmount;
    bytes32 public merkleRoot;
    address public constant withdrawAddress = 0x62aa1F53eB91d2Bb89aF32348f372B2c4CBD5F82;

    constructor(
    ) ERC721A("SanuQN", "SQN") {
        setBaseURI("https://data.zqn.wtf/sanuqn/metadata/");
        setMerkleRoot(0x32da4f9f9fc5fa8c8280603635253f88da8d9602fbebcb342c4e4cd815dc6902);
        _safeMint(0x3616dB871945a156Ec8Dd9Bd6b62c443E77EdD42, 200);
        _safeMint(0xdEcf4B112d4120B6998e5020a6B4819E490F7db6, 100);
        _safeMint(0x62aa1F53eB91d2Bb89aF32348f372B2c4CBD5F82, 200);
        _safeMint(0x621Ce1f1fe318aCA560aD96c083918Fbd89b7D6B, 20);
        _safeMint(0x033602CDD751F7AC33ae0e76e5ce20a144967907, 20);
        _safeMint(0x2014be1d423035142daA05Bde65268F75429Fb1a, 20);
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

    //pre sale 1 
    //onlyWhitelisted=true
    //presale=true

    //pre sale 2
    //onlyWhitelisted=true
    //presale=false

    //public sale
    //onlyWhitelisted=false
    //presale=false

    // public
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");

        if(onlyWhitelisted == true) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxMintAmount));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not whitelisted");
            if(preSale == true){
                require(_mintAmount <= _maxMintAmount - whitelistMintedAmount[msg.sender] , "max NFT per address exceeded");
            }
        }
        //check end

        if(onlyWhitelisted == true) {
            if(preSale == true){
                whitelistMintedAmount[msg.sender] += _mintAmount;
            }
        }
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
    function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
        maxSupply = _maxSupply;
    }

    function setOCM(address _address) public onlyOwner() {
        OCM = iOCM(_address);
    }

    function setUseOnChainMetadata(bool _useOnChainMetadata) public onlyOwner() {
        useOnChainMetadata = _useOnChainMetadata;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
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

    function setPreSale(bool _state) public onlyOwner {
        preSale = _state;
    }
 
    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


}