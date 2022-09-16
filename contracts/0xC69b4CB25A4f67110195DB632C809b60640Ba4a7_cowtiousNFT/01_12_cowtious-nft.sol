// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721r.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract cowtiousNFT is ERC721r, Ownable,ReentrancyGuard{

 

uint256 public mintPrice;
uint256 public immutable maxPerWallet;

bool public isPublicMintEnabled;
string internal baseTokenUri;
address payable public withdrawWallet;
mapping(address => uint256) public walletMints;

constructor(uint256 mintprice_,uint256 maxPerWallet_,uint256 maxSupply_) ERC721r('cowtiousNFT','CWO',maxSupply_){
   maxPerWallet=maxPerWallet_;
   mintPrice=mintprice_;

}

function setMintPrice(uint256 mintprice_) external onlyOwner{
    mintPrice=mintprice_;

}

function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner{

    baseTokenUri = baseTokenUri_;

 }

function tokenURI(uint256 tokenId_) public view override returns (string memory){
        require(_exists(tokenId_),'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri,Strings.toString(tokenId_),".json"));
}


function withdraw() external onlyOwner{
(bool success,)= withdrawWallet.call{value:address(this).balance}('');
require(success,'withdraw failed');
}

function mint(uint256 quantity_)
 external payable{
    require(msg.value == quantity_ * mintPrice,'Wrong Mint Value');
    require(walletMints[msg.sender]+quantity_ <= maxPerWallet,'exceed max wallet');
    walletMints[msg.sender] += quantity_ ;
     _mintRandom(msg.sender,quantity_);
   
 }
 
  
 }