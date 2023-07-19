//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//                                                                                   ..                                                                 
//                                                                               .';;;.                                                                 
//                                                                             .;lc,.                                                                   
//                                                                         .,;:lc'.                                                                     
//                                                                       .;looc;.                                                                       
//                                                            .',.     .;lol:;.                                                                         
//            .....                                           ,lol:. .clolc,.                                                                           
//       ..'''',,,,''...   .'''''.       ..'''''..            ,ooloc:loll;.           .'''''''''''......      ...''''''''....     .'''..'.''''.''..     
//      .,,','....''''''.  .','',.    ..'',,'..               .,loooollo:.            .',','.......'',,,'.  ..','''.....',,,'..   .,''''..........      
//     .','','..........   .','',....'''''...                   ;loloooc.             .',','.      .','',. .','''..     .......   .,,,,..               
//      ..''',,,,,,,'''..  .','',''',',,'..                   .,llolllol;.            .','''.......'''','. .',','.      .......   .,'','''''''''.       
//       ..........',,',.  .',''',,''.',,''..                .:lolocclooo:.           .','''''''''''''''.  .',',,..    .'',,,,'.  .,',,.........        
//      .'''''....'','''.  .'''','..   ..''','..            ,loolo:...;lol;           .',','.     ..''''.   .''''''......'''','.  .,'','...........     
//      ...''',','''..    .'''''.       ..'''''..        .;lolol;.    .:ll'          .'''''.      ..''''.    ...''',,,'''...'.   .'''''''''''''''.     
//            .....                                      .cloolc'        .c:.                                      .....                                
//                                                     .,coool:.          ..                                                                            
//                                                    .:lolol,.                                                                                         
//                                                   .colol:.                                                                                           
//                                                  .coolc,.                                                                                            
//                                                  .cc,..                                                                                              
//                                                  ...                                                                                                 
//

// Skorge Elysium Key Contract
contract SkorgeElysiumKey is ERC721URIStorage, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    //Important constants
    bool public saleIsActive = false;
    uint public constant MAX_TOKENS = 337;
    uint public constant NUMBER_RESERVED_TOKENS = 37;
    uint public constant PRICE = 200001000000000000;
    uint public constant ADDRESS_MAX_MINTS = 2;

    //Mapping to check if addresses have already max minted
    mapping(address => bool) alreadyMinted;
    mapping(address => uint) numberOfMintsOnAddress;
    
    //Base token URI
    string public _baseTokenURI;

    //Constructor, sets the base URI
    constructor(string memory baseURI) ERC721("Skorge Elysium Key", "SEK") {
        _setBaseURI(baseURI);
    }

    uint reservedTokensMinted = 0;

    //Payable addresses
    address payable private discordGuy = payable(0xB837C4a0d9562C0B75256b9d1F5acC02760a1fCF);
    address payable private maple = payable(0xB682F5C222A3d07aa23603d524978C551BcD00b6);
    address payable private devGuy = payable(0xcEB5E5c55bB585CFaEF92aeB1609C4384Ec1890e);
  
    //Function to deal with public key minting
    function mintElysiumKey(uint256 amount) external payable
    {
        require(saleIsActive, "Sale must be active to mint tokens");
        require(!alreadyMinted[msg.sender], "Sender already minted all their allocated tokens");
        require(numberOfMintsOnAddress[msg.sender] + amount <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(tokenIds.current() >= 0 && tokenIds.current() + amount <= (MAX_TOKENS-NUMBER_RESERVED_TOKENS), "Purchase would exceed max supply");
        require(amount > 0 && amount <= 2, "Max 2 per transaction");
        require(msg.value >= amount * PRICE, "Not enough ETH sent, please check mint price");
        
          for (uint i = 0; i < amount; i++){
            tokenIds.increment();
            numberOfMintsOnAddress[msg.sender]++;
            uint256 newItemId = tokenIds.current();
            _safeMint(msg.sender, newItemId); //Safe mint checks if ID is duplicate
          } 

            if(numberOfMintsOnAddress[msg.sender] == ADDRESS_MAX_MINTS){
              alreadyMinted[msg.sender] = true;
          }
    }
    
    //Function to deal with reserved elysium key minting
    //We can replace recipient here and just use msg.sender in the mint function
    //tokenURI is the IPFS URI
    function mintReservedElysiumKey(address recipient, uint256 amount) external
    {
        require(msg.sender == discordGuy || msg.sender == maple || msg.sender == devGuy || msg.sender == owner(), "Invalid Sender");
        require(amount > 0 && tokenIds.current() >= 0 && tokenIds.current() + amount <= MAX_TOKENS && reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "Maximum reserves already minted");
        
        for (uint i = 0; i < amount; i++){
            tokenIds.increment();

            uint256 newItemId = tokenIds.current();
            _safeMint(recipient, newItemId); //Safe mint checks if ID is duplicate

            reservedTokensMinted++;
        }
    }

    //Withdraws to the relevant wallets
    function withdraw() public onlyOwner
    {
        require(msg.sender == owner(), "Invalid sender");

        (bool dg, ) = discordGuy.call{value: address(this).balance * 1/3}("");
        require(dg);

        (bool mg, ) = maple.call{value: address(this).balance * 50/100}("");
        require(mg);

        (bool dev, ) = devGuy.call{value: address(this).balance}("");
        require(dev);
    }

    //Toggles if keys are on sale
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    ////
    //URI management part
    ////
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    //Compliance with ERC721Enumerable, set to not be able to be called as we don't want burns!
     function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyOwner {
        super._burn(tokenId);
    }

}