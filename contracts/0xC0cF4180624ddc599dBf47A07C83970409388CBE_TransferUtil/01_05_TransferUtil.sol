// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TransferUtil is Ownable{

  address public tokenAddress;
  uint32 private contractMaxSupply;
  IERC721 tokenContract;

  constructor(address _tokenAddress, uint32 _contractMaxSupply){
      tokenAddress = _tokenAddress;
      contractMaxSupply = _contractMaxSupply;
      tokenContract = IERC721(_tokenAddress);
  }

  function distributeTokens(address[] calldata recipients) external onlyOwner{
    require(tokenContract.balanceOf(owner()) >= recipients.length, "You do not have enough tokens for all recipients.");
    require(tokenContract.isApprovedForAll(msg.sender, address(this)) == true, "Utility is not approved for transferring tokens.");
    
    uint32 count = 0;
    uint32 tokenTrack = 1;

    while(count != recipients.length && tokenTrack <= contractMaxSupply){
        if(tokenContract.ownerOf(tokenTrack) == msg.sender){
          tokenContract.safeTransferFrom(msg.sender, recipients[count], tokenTrack);
          count = count + 1;
        }
        tokenTrack = tokenTrack + 1;
    }
  }

  function setTokenAddr(address _newAddress) public onlyOwner {
    tokenAddress = _newAddress;
    tokenContract = IERC721(tokenAddress);
  }
  
  function setMaxSupply(uint32 _newMax) public onlyOwner {
    contractMaxSupply = _newMax;
  }

}