// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Administration.sol";
import "./NFTEvents.sol";
import "./interface/IStrip.sol";

contract Assets is Administration, NFTEvents {
    
    uint public strippersCount = 0;
    uint public clubsCount = 0;
    uint public namePriceStripper = 200 ether;
    uint public stripperSupply = 3000;
    uint8 public STRIPPER = 0;
    uint8 public CLUB = 1;
    
    IStrip public COIN;
    
    struct Asset {
        uint id;
        uint tokenType;
        uint earn;
        uint withdraw;
        uint born;
        string name;
        bool active;
    }
    
    Asset[] public assets;
    
    function setCoinAddress(address addr) public onlyAdmin {
        COIN = IStrip(addr);
    }
    
    function getAssetByTokenId(uint tokenId) public view returns(Asset memory, uint idx) {
        uint i = 0;
        Asset memory asset;
        while(i < assets.length){
            if(assets[i].id == tokenId){
                asset = assets[i];
                return(assets[i],i);
            }
            i++;
        }
        revert("tokenId not found");
    }
    
    function setNamePriceStripper(uint newPrice) external onlyAdmin {
        namePriceStripper = newPrice;
    }
    
    function adminSetAssetName(uint tokenId, string calldata name) external onlyAdmin {
        (,uint idx) = getAssetByTokenId(tokenId);
        assets[idx].name = name;
        emit NewAssetName(_msgSender(), tokenId, name);
    }
    
    function setStripperSupply(uint supply) external onlyAdmin {
        stripperSupply = supply;
        emit NewTotalSupply(_msgSender(), supply);
    }
    
    function totalSupply() external view returns (uint) {
        return stripperSupply + clubsCount;
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}