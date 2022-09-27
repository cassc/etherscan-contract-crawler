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


//burnin' contract
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


contract itadakimasuman is ERC721A, Ownable, Minter, Burner {

    constructor(
    ) ERC721A("ItadakimasuManRevenge", "IMR") {
        setBaseURI("ipfs://QmUW43vwD7iB8jiwwAcdrYLgrSf9AU98TZ88XV3nrAy9BF/");
        setMerkleRoot(0x03e4e84e3b26aea2fcb769eaf8b9eb096719834633550decf7dc163189e2606b);
        _safeMint(0xBcA7b4FBA4262a7E369875042d73981921764b30, 1);
    }


    //
    //withdraw section
    //

    address public constant withdrawAddress = 0xcAF5a271c208791e63E576142451f2651894f43F;

    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }



    //
    //mint part
    //

    uint256 public cost = 1000000000000000;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 200;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    bool public mintCount = true;
    mapping(address => uint256) public whitelistMintedAmount;
    mapping(address => uint256) public publicSaleMintedAmount;
    bytes32 public merkleRoot;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");
        if(onlyWhitelisted == true) {
            bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not whitelisted");
            if(mintCount == true){
                require(_mintAmount <= _maxMintAmount - whitelistMintedAmount[msg.sender] , "max NFT per address exceeded");
                whitelistMintedAmount[msg.sender] += _mintAmount;
            }
        }else{
            if(mintCount == true){
                publicSaleMintedAmount[msg.sender] += _mintAmount;
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

    function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
        maxSupply = _maxSupply;
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
  
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMintCount(bool _state) public onlyOwner {
        mintCount = _state;
    }
 

    //
    //URI section
    //

    string baseURI;
    string public baseExtension = ".json";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }


    //
    //burnin' section
    //
    
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


    //
    //on chain metadata section
    //

    iOCM public OCM;
    bool public useOnChainMetadata = false;

    function setOCM(address _address) public onlyOwner() {
        OCM = iOCM(_address);
    }

    function setUseOnChainMetadata(bool _useOnChainMetadata) public onlyOwner() {
        useOnChainMetadata = _useOnChainMetadata;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useOnChainMetadata == true) {
            return OCM.tokenURI(tokenId);
        } else {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
        }
    }



    //
    //viewer section
    //

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


    //
    //sbt section
    //

    bool public isSBT = false;
    
    function setIsSBT(bool _state) public onlyOwner {
        isSBT = _state;
    }

    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( isSBT == false || from == address(0), "transfer is prohibited");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require( isSBT == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require( isSBT == false , "approve is prohibited");
        super.approve(to, tokenId);
    }


}