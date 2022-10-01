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

import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



//on chain metadata interface
interface iOCM {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract NFTCheckerSBT is ERC721A, Ownable, AccessControl{

    constructor(
    ) ERC721A("NFTCheckerSBT", "NFTCK") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE       , msg.sender);
        _setupRole(BURNER_ROLE       , msg.sender);
        _setupRole(AIRDROP_ROLE      , msg.sender);
        _safeMint(0xdEcf4B112d4120B6998e5020a6B4819E490F7db6, 1);
    }


    //
    //withdraw section
    //

    address public constant withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //mint section
    //

    uint256 public cost = 0;
    uint256 public maxSupply = 10000;
    bool public paused = false;
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function mint() public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(totalSupply() + 1 <= maxSupply, "max NFT limit exceeded");
        require(cost <= msg.value, "insufficient funds");
        require(balanceOf(msg.sender) == 0 , "You already have SBT");
        _safeMint(msg.sender, 1);
    }

    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public {
        require(hasRole(AIRDROP_ROLE, msg.sender), "Caller is not a air dropper");
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

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
  
    function pause(bool _state) public onlyOwner {
        paused = _state;
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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    //
    //burnin' section
    //

    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE  = keccak256("BURNER_ROLE");
    
    function externalMint(address _address , uint256 _amount ) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require( _nextTokenId() -1 + _amount <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }

    function externalBurn(address _address, uint256[] memory _burnTokenIds) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
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
    bool public useOnChainMetadata = true;

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



    //
    //sbt section
    //

    bool public isSBT = true;

    function setIsSBT(bool _state) public onlyOwner {
        isSBT = _state;
    }

    function _sbt() internal view returns (bool) {
        return isSBT;
    }    

    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( _sbt() == false || from == address(0) || to == address(0x000000000000000000000000000000000000dEaD), "transfer is prohibited");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require( _sbt() == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require( _sbt() == false , "approve is prohibited");
        super.approve(to, tokenId);
    }



    //
    //override
    //

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}