// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// both for OpenSea Proxy addresses
contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract MintopolyCards is ERC1155, Ownable {
    
    address proxyRegistryAddress;
    
    uint256 private BASE_CARD_SUPPLY_CAP = 12000;
    uint256 private BONUS_CARD_SUPPLY_CAP = 4000;
    uint256 private MAX_SUPPLY_PER_BASE_ID = 30;
    uint256 private MAX_SUPPLY_PER_BONUS_ID = 1000;

    uint256 public totalMintedBaseCards;
    uint256 public totalMintedBonusCards;

    mapping(uint256 => uint256) public mintedCards;
    
    
    constructor() ERC1155("https://mintopoly.io/cards_api/{id}.json") {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }

    
    function mintCards(uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        bool idAlreadyExists = false;
        uint totalNewBaseCards;
        uint totalNewBonusCards;
        uint highestBaseCardSupply;
        uint highestBonusCardSupply;
        
        for(uint i = 0; i < _amounts.length; i++) {
            if(mintedCards[_ids[i]] > 0) { 
                idAlreadyExists = true;
            }
            if(_ids[i] == 1) { // ID 1 is the unique mintopolist card – supply of 50 – exempt from 30 per card limit
                totalNewBaseCards += _amounts[i];
            } else if (_ids[i] <= 750) { // base cards have IDs < 750
                totalNewBaseCards += _amounts[i];
                if (_amounts[i] > highestBaseCardSupply) {
                    highestBaseCardSupply = _amounts[i];
                }
            } else { // bonus cards have IDs 9XX, so anything above 750
                totalNewBonusCards += _amounts[i];
                if (_amounts[i] > highestBonusCardSupply) {
                    highestBonusCardSupply = _amounts[i];
                }
            }
        }
        
        require(!idAlreadyExists, "ID Already Exists");
        require(totalMintedBaseCards + totalNewBaseCards <= BASE_CARD_SUPPLY_CAP, "12,000 base cards have already been minted");
        require(totalMintedBonusCards + totalNewBonusCards <= BONUS_CARD_SUPPLY_CAP, "4,000 bonus cards have already been minted");
        require(highestBaseCardSupply <= MAX_SUPPLY_PER_BASE_ID, "max supply for base cards is 30");
        require(highestBonusCardSupply <= MAX_SUPPLY_PER_BONUS_ID, "max supply for bonus cards is 1000");

        for(uint i = 0; i < _amounts.length; i++) {
            mintedCards[_ids[i]] = _amounts[i];
        }
        
        totalMintedBaseCards += totalNewBaseCards;
        totalMintedBonusCards += totalNewBonusCards;

         _mintBatch(msg.sender, _ids, _amounts, "");
    }
    
    
    
    /**
     * Override renounceOwnership to prevent disaster
     */
    function renounceOwnership() override public pure {
        revert("renounceOwnership cannot be called");
    }
    
    
    
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
          return true;
        }
        return ERC1155.isApprovedForAll(_owner, _operator);
      }

    
}