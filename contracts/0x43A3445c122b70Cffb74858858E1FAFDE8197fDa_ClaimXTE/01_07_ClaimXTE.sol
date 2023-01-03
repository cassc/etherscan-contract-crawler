//SPDX-License-Identifier: MIT
//ndgtlft etm.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

//interface block
interface TokenInterface {
    function mintToken(address _to, uint256 _amount) external;
}

contract ClaimXTE is ReentrancyGuard, Ownable { 

// config parameter block
    address public nftCollection = 0x5b7A317A300699531cA4673473b84b6a7cbBC294; 
    address public tokenAddress = 0xfdE4dD749849F6D7F360df174fAD51243cFC3c3E;
    uint256 public dayReward = 11574074074075; // 1day=1token (reward/86400sec)
    uint256[] public sectionEndIds; 
    uint256[] public sectionStartTimes;
    mapping(uint256 => uint256) lastClaims;
    TokenInterface tokenContract = TokenInterface(tokenAddress);  

    function claimToken() external nonReentrant {
        address _owner = msg.sender;
        uint256 timeAmount;
        uint256 tokenAmount;
        uint256 timeCount;
        uint256 tokenId;
        uint256 NFTsNum = IERC721Enumerable(nftCollection).balanceOf(_owner);
        require(tx.origin == msg.sender, "not externally owned account");
        require(NFTsNum != 0, "You are not holding NFTcollection!");

        //get tokenId        
        for(uint256 i = 0; i < NFTsNum; i++){
            tokenId = IERC721Enumerable(nftCollection).tokenOfOwnerByIndex(_owner,i);
        
            //get time
            if(lastClaims[tokenId] != 0 ){
            timeCount = block.timestamp - lastClaims[tokenId]; 
            }else if(lastClaims[tokenId] == 0){
                 for(uint256 j = 0; j < sectionEndIds.length; j++){
                     if(tokenId <= sectionEndIds[j]){
                        timeCount = block.timestamp - sectionStartTimes[j];
                        break;                                                      
                     }
                 }
            }
            timeAmount = timeAmount + timeCount;
            lastClaims[tokenId] = block.timestamp;
        }      
        tokenAmount = timeAmount * dayReward; 
        tokenContract.mintToken(_owner, tokenAmount); 
    }

//view block
    function viewNFTsNum(address _owner)external view returns(uint256){
        return IERC721Enumerable(nftCollection).balanceOf(_owner);
    }

    function viewReward(address _owner)external view returns(uint256){
        uint256 timeAmount;
        uint256 tokenId;
        uint256 timeCount;
        uint256 NFTsNum = IERC721Enumerable(nftCollection).balanceOf(_owner);
        require(NFTsNum != 0, "You are not holding NFTcollection!");
        
        //get tokenId
        for(uint256 i = 0; i < NFTsNum; i++){
            tokenId = IERC721Enumerable(nftCollection).tokenOfOwnerByIndex(_owner,i);
        
            //get time
            if(lastClaims[tokenId] != 0 ){
            timeCount = block.timestamp - lastClaims[tokenId]; 
            }else if(lastClaims[tokenId] == 0){
                 for(uint256 j = 0; j < sectionEndIds.length; j++){
                     if(tokenId <= sectionEndIds[j]){
                        timeCount = block.timestamp - sectionStartTimes[j];
                        break;                                       
                     }
                 }
            }       
            timeAmount = timeAmount + timeCount;
        }
        return timeAmount * dayReward;
    }

//view block
    function getSectionEndIds() external view returns (uint256[] memory) {
        return sectionEndIds;
    }

    function getSectionStartTimes() external view returns (uint256[] memory) {
        return sectionStartTimes;
    }

//onlyOwner block
    function setNftCollection(address _nftCollection)external onlyOwner{
        nftCollection = _nftCollection;
    }
    
    function setTokenAddress(address _tokenAddress)external onlyOwner{
        tokenAddress = _tokenAddress;
    }

    function setDayReward(uint256 _newDayReward)external onlyOwner{
        dayReward = _newDayReward;
    }

    function addSection(uint256 _sectionEndId, uint256 _sectionStartTime)external onlyOwner{
        sectionEndIds.push(_sectionEndId);
        sectionStartTimes.push(_sectionStartTime);
    }

    function editSection(uint256 _editIndexNumber, uint256 _newSectionEndId, uint256 _newSectionStartTime)external onlyOwner{
        sectionEndIds[_editIndexNumber] = _newSectionEndId;
        sectionStartTimes[_editIndexNumber] = _newSectionStartTime;
    }
}