// SPDX-License-Identifier: MIT
// Author: Sobi & Chu

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721S.sol";

contract WorldTennisLeague is Ownable, ERC721S, ReentrancyGuard {
    enum ContractStatus {
        Paused,
        Public
    }
    ContractStatus public contractStatus = ContractStatus.Paused;

    string  public baseURI;
    string  public baseExtension = ".json";
    uint256 public price = 0.03 ether;
    uint256 public totalMintSupply = 2000;
    uint256 public publicMintTransactionLimit = 5;

    //This modifier is not included in minting function as it insures that the mint() is not called by another contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(string memory contractBaseURI)
    ERC721S ("World Tennis League", "WTL") {
        baseURI = contractBaseURI;
    }

    function _baseURI() internal view override(ERC721S) returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require( exists(tokenId) , "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension)): "";
    }

    function exists(uint tokenId) public view returns(bool){
        bool status =  _exists(tokenId) ;
        return status;
    }

    function _startTokenId() internal view virtual override(ERC721S) returns (uint256) {
        return 1; //if anyone chaning this then also change the function safeTransferFromEXS
    }

    function mint(uint64 quantity) public onlyOwner {// set to onlyOwner will be changed after asking EXS team
        require(contractStatus == ContractStatus.Public, "Public minting not available"); 
        // require(msg.value >= price * quantity, "Not enough ETH sent");
        require(_totalMinted() + quantity <= totalMintSupply, "Not enough supply");
        // require(quantity <= publicMintTransactionLimit, "Exceeds allowed transaction limit");

        _safeMint(msg.sender, quantity);
    }

    function burn(uint256 tokenId) public{
        _burn(tokenId);
    }
    

    // Owner Only

    function setContractStatus(ContractStatus status) public onlyOwner {
        contractStatus = status;
    }

    function setTotalMintSupply(uint256 supply) public onlyOwner {
        totalMintSupply = supply;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function teamMint(address[] memory addresses, uint64[] memory quantities) external onlyOwner {
        require(addresses.length == quantities.length, "addresses does not match quatities length");
        uint64 totalQuantity = 0;
        for (uint i = 0; i < quantities.length; i++) {
            totalQuantity += quantities[i];
        }
        require(_totalMinted() + totalQuantity <= totalMintSupply, "Not enough supply");
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantities[i]);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transaction Unsuccessful");
    }

    function safeTransferFromEXS( address from, address to, uint256 tokenIdFrom, uint256 tokenIdTo) public onlyOwner{
        
        uint256 tokenId = tokenIdFrom;
        for( uint256 i = tokenId; i<= tokenIdTo; i++){
            safeTransferFrom(from, to, i, '');
        }
    }
}