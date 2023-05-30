// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/*
MutantLads powered by PuzlWorld
                                        .........                               
                                       ..,,,,,,,,..                             
                                          .,,,,,,,,,.                           
                                    .,,,,,,,,,,,,,,,,,,,,,..                    
                                  ..,,,,,,,,,,,,,,,,,,,,,,,,..                  
                                 .,,,,,,,,,,,,,,,,,,,,,,,,,,,,.                 
                                 .,,,,,,,,,,,,,,,,,,,,,,,,,,,,.                 
                                 .,,,,,,.....,,,,,,,,,,,,,,,,..                 
                                 .,,,,,.  ...,,,,,,,,,,,....,,.                 
                                 .,,,,,.  .,##,,,,,,,,,,. .,##,.                
                                 .,,,,,.  .#/##,,,,,,,,,,,,,,,.                 
     ..,....                     .,,,,,,,,,,###,,,,,.. .,,,,,,.                 
   .,,#/##,,..                   .,,,,,,,,,,,,...,,,.    ..,,,.                 
  ..,#((/##,,,.                  .,,,,,,,,,,,.   .,,.      .,,.                 
    .,/(/##,,,.                  .,,,,,,,,,,,.   ....      .,,.                 
 .,#//###,,,...                  .,,,,,,,,,,,.                                  
 .#((/#,,,....                 ..,,,,,,,,,,,,,.      ..               ..,,,,.   
 .#((/#,,,..                 ..,,,,,,,,,,,,,,,,... ..,,,.           .,###//#.   
 .#((/#,,,..   .,,.       .....,,,,,,,,,,,,,,,,,,,,,,,,,,,####,.  .,#/((#.      
 .#((/#,,,...,,,,,,,,,.........,,,,,,,,,,,,,,,,,,,,,,,,####/((#.  .,#/((#.      
 .,///#,,,,,,,###/###,,,,,,....,,,,,,,,,,,,,,,,,,,,,,.....,/((#.  .,##//##,,.   
  .,#####,,,###//(//####,,,,,,.,,,,,,,,,,,,,,,,,,,,,.      ,##,.  ..,,,#//(/,   
     .#/####/((/###/((/####,,,,...,,,,,,,,,,,,,,,,,,.                .,#//(/,   
  .......,,#/((/#,,,,#////#,,,,,,,.,,,,,,,,,,,#####,.             ..,#####,,.   
  .,,,..,,,#///#.....,###/////////########,...,,####,............,,####,,..     
  ..,,,,,,,,,,,.    .....,#////////######,.    ..,,,,,,,,,,,,,,,,,,,,,..        
  
  dev x hwonder
  always remember 1000000000000000000 1eth
  */

interface ILadInterface  {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract MutantLads is ERC721URIStorage, Ownable {
     using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    uint256 public constant MAX_NFT = 5001;

    uint256 public CLONE_LAB = 0;

    address public operator = msg.sender;

    address public creatorAddress = msg.sender;

    string private _baseURIextended;

    uint256 private COST = 0.00 ether;

    uint256 private INCRM = 0.00 ether;

    address public LARVA = 0x5755Ab845dDEaB27E1cfCe00cd629B2e135Acc3d;

    mapping(uint256 => bool) public clones;

    function mutated() external view returns (uint) {
        return _tokenIdTracker.current();
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function updateOperator(address _operator) public onlyOwner {
       operator = _operator;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function dutchClone() external view returns (uint256) {
        return COST + (INCRM *  ((_tokenIdTracker.current()+1 - CLONE_LAB)/100));
    }

    function isMutated (uint256 _cloneid) external view returns (bool) {
        return clones[_cloneid];
    }
 
    function setDutch(uint256 _newCost, uint256 _newIncrm) external onlyOwner {
        CLONE_LAB = _tokenIdTracker.current();
        COST = _newCost;
        INCRM = _newIncrm;
    }

    function mutateLad(uint256 _cloneid, uint256 noncemap, string memory _hashref, string memory _hashmap)  external payable returns (uint256) {
        uint256 cost = COST + (INCRM *  ((_tokenIdTracker.current()+1 - CLONE_LAB)/100));
        bool haslad = ILadInterface(LARVA).ownerOf(_cloneid) == msg.sender;
        if (cost == 0) require(haslad, "Nachos");
        require(_cloneid < 5001, "Imaginary");
        require(!clones[_cloneid], "Already Mutated");
        if (cost > 0 && !haslad) require(msg.value >= cost, "Need more");
        require(_totalSupply() + 1 < MAX_NFT, "Maxout");
        clones[_cloneid] = true;
        _tokenIdTracker.increment();
        uint256 newItemId = _tokenIdTracker.current();
        _mint(msg.sender, newItemId);
        return newItemId;
    }
    
     function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    constructor() ERC721("Mutant Lads", "MTNLARVA") Ownable() {}
}