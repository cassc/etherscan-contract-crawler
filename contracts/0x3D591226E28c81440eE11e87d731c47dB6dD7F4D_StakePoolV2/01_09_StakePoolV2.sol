/***
* MIT License
* ===========
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*                             
*     __  _____    __    ____ 
*    / / / /   |  / /   / __ \
*   / /_/ / /| | / /   / / / /
*  / __  / ___ |/ /___/ /_/ / 
* /_/ /_/_/  |_/_____/\____/  
*                             
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security//ReentrancyGuard.sol";

contract StakePoolV2 is ReentrancyGuard, Pausable, Ownable {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public _erc721;
    uint256 public _stakeLimit;

    struct StakeCondition{
        uint256 duration;
        uint256 rewardRate;
    }

    struct StakeInfo{
        uint256 startTime;
        uint256 accumulateTime;
    }

    struct StakeRecord{
        uint256 tokenId;
        uint256 accumulateTime;
        uint256 extraTime;
        uint256 stakeTime;
        uint256 leftLockTime;
    }

    EnumerableSet.UintSet private _stakeTypes;
    mapping(uint256 => StakeCondition) public _stakeCondition;  // staketype=>StakeCondition;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private _recordStakeIds;  // staketype=>address=>tokenids;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private _curStakeIds;  // staketype=>address=>tokenids;
    mapping(uint256 => mapping(address => mapping( uint256 => StakeInfo ))) public _stakeInfos; //staketype=>address=>tokenid=>StakeInfo

    event eStake( uint256 tokenId, address owner, uint256 action, uint256 timestamp );
    event eWithdraw( uint256 tokenId, address owner, uint256 action,uint256 duration, uint256 timestamp );

    constructor(IERC721 erc721, uint256 stakeLimit) {
        _erc721 = erc721;
        _stakeLimit = stakeLimit;

        setStakeCondition(0,0,0);
        setStakeCondition(1,7*24*3600,100);
        setStakeCondition(2,30*24*3600,200);
    }


    function setErc721(IERC721 erc721) public onlyOwner{
        _erc721 = erc721;
    }
    
    function setLimit(uint256 limit) public onlyOwner{
        _stakeLimit = limit;
    }

    function close(uint256 stakeType) public onlyOwner{
        _stakeTypes.remove(stakeType);
    }

    function setStakeCondition(uint256 stakeType, uint256 duration, uint256 rewardRate) public onlyOwner{
        _stakeCondition[stakeType].duration = duration;
        _stakeCondition[stakeType].rewardRate = rewardRate;

        _stakeTypes.add(stakeType);
    }
    
    function onERC721Received(address /*operator*/ , address /*from*/ , uint256 /*tokenId*/, bytes calldata  /*data*/) external pure returns (bytes4) {

        return this.onERC721Received.selector;
    }

    function getCurStakeTokens(uint256 stakeType, address owner) public view returns(uint256[] memory ){

        require(_stakeTypes.contains(stakeType), "invalid stake type !");

        return _curStakeIds[stakeType][owner].values();
    }

    function getRecordStakeTokens(uint256 stakeType, address owner) public view returns(uint256[] memory ){

        require(_stakeTypes.contains(stakeType), "invalid stake type !");

        return _recordStakeIds[stakeType][owner].values();
    }

    function getStakeTypes() public view returns(uint256[] memory ){
        return _stakeTypes.values();
    }

    function getCurStakeInfo(uint256 stakeType, address owner) public view returns(StakeRecord[] memory ){

        uint256[] memory tokenIds  = _curStakeIds[stakeType][owner].values();

        StakeRecord[] memory records = new StakeRecord[](tokenIds.length);

        return _getStakeInfo(stakeType,owner,tokenIds,records, 0);

    }

    function getStakeInfo(uint256 stakeType,address owner) public view returns(StakeRecord[] memory ){

        uint256[] memory tokenIds  = _recordStakeIds[stakeType][owner].values();

        StakeRecord[] memory records = new StakeRecord[](tokenIds.length);

        return _getStakeInfo(stakeType,owner,tokenIds,records, 0);

    }

    function getAllStakeInfo(address owner) public view returns(StakeRecord[] memory ){

        uint256 alllen = 0;
        for(uint256 i=0; i<_stakeTypes.length(); i++){
            alllen += _recordStakeIds[_stakeTypes.at(i)][owner].length();
        }

        StakeRecord[] memory records = new StakeRecord[](alllen);
        uint256 offset = 0;
        for(uint256 i=0; i<_stakeTypes.length(); i++){
           
            uint256[] memory tokenIds  = _recordStakeIds[_stakeTypes.at(i)][owner].values();
            if(tokenIds.length >0){
                records = _getStakeInfo(_stakeTypes.at(i),owner,tokenIds,records,offset);
                offset += _recordStakeIds[_stakeTypes.at(i)][owner].length();
            }
        }

        return records;
    }


    function _getStakeInfo(uint256 stakeType, address owner, uint256[] memory tokenIds, StakeRecord[] memory records,uint256 offset ) 
    internal view returns (StakeRecord[] memory ) {

        require(_stakeTypes.contains(stakeType), "invalid stake type !");

        
        for( uint256 i=0; i<tokenIds.length; i++){
            
            uint256 start = i + offset;
            records[start].tokenId = tokenIds[i];
            StakeInfo memory sInfo = _stakeInfos[stakeType][owner][tokenIds[i]];
            records[start].accumulateTime = sInfo.accumulateTime;
            records[start].leftLockTime=0;
            records[start].extraTime=0;
            records[start].stakeTime=0;
            
            if(sInfo.startTime>0){
  
                uint256 delta = block.timestamp.sub(sInfo.startTime);
                uint256 duration = _stakeCondition[stakeType].duration;

                if(duration==0){
                    records[start].extraTime=delta;

                }
                else if(delta<duration){
                    records[start].leftLockTime = duration.sub(delta);
                }

                records[start].stakeTime=delta;
            }
        }

        return records;
    }

    function stakeNFTs(uint256 stakeType, uint256[] calldata nftList) public whenNotPaused nonReentrant {

        require(_stakeTypes.contains(stakeType), "invalid stake type !");

        uint256 stakeAmount = nftList.length+_curStakeIds[stakeType][msg.sender].length();
        require( stakeAmount <= _stakeLimit, "stake amount over limit! " );

        for( uint256 i=0; i<nftList.length; i++){

            _erc721.safeTransferFrom(msg.sender, address(this), nftList[i]);
        
            _curStakeIds[stakeType][msg.sender].add(nftList[i]);
            _recordStakeIds[stakeType][msg.sender].add(nftList[i]);

            _stakeInfos[stakeType][msg.sender][nftList[i]].startTime=block.timestamp;

            emit eStake(nftList[i], msg.sender, stakeType, block.timestamp);

        }

    }

    function withdrawNFTs( uint256 stakeType, uint256[] calldata nftList) public whenNotPaused nonReentrant {

        for (uint256 i = 0; i<nftList.length; i++) {

            uint256 tokenId = nftList[i];
            require(_stakeTypes.contains(stakeType), "invalid stake type !");
            require(_curStakeIds[stakeType][msg.sender].contains(tokenId),"invalid tokenid or staketype!");

            StakeInfo storage sInfo = _stakeInfos[stakeType][msg.sender][tokenId];
            uint256 delta = block.timestamp.sub(sInfo.startTime);

            require(delta >= _stakeCondition[stakeType].duration ,"token pledge has not expired!");

            if(_stakeCondition[stakeType].duration>0){
                delta = _stakeCondition[stakeType].duration;
            }

            _curStakeIds[stakeType][msg.sender].remove(tokenId);
            _erc721.safeTransferFrom(address(this), msg.sender, tokenId);

            sInfo.startTime = 0;
            uint256 reward = (_stakeCondition[stakeType].rewardRate*delta/10000).add(delta);
            sInfo.accumulateTime = sInfo.accumulateTime.add(reward);

            emit eWithdraw(tokenId, msg.sender, stakeType, reward, block.timestamp);
        }
       
    }

    function withdrawByType(uint256 stakeType) public whenNotPaused nonReentrant {

        uint256[] memory ids = _curStakeIds[stakeType][msg.sender].values();
        require(ids.length>0,"there are not any nfts staking");

        for (uint256 i = 0; i <ids.length; i++) {
            _withdraw(stakeType, ids[i]);
        }
    }

    function withdrawAll() public whenNotPaused nonReentrant {

        uint256 stakeType;
        for(uint256 k=0; k<_stakeTypes.length(); k++){
            stakeType = _stakeTypes.at(k);

            uint256[] memory ids = _curStakeIds[stakeType][msg.sender].values();
            // require(ids.length>0,"there are not any nfts staking");

            for (uint256 i = 0; i <ids.length; i++) {
                _withdraw(stakeType, ids[i]);
            }
        }
    }

    function _withdraw(uint256 stakeType, uint256 tokenId ) internal   {

        require(_stakeTypes.contains(stakeType), "invalid stake type !");

        StakeInfo storage sInfo = _stakeInfos[stakeType][msg.sender][tokenId];

        require(_curStakeIds[stakeType][msg.sender].contains(tokenId),"invalid tokenid or staketype!");
        //require( sInfo.startTime >0, "invalid stake status! ");

        uint256 delta = block.timestamp.sub(sInfo.startTime);
        
        if(delta>=_stakeCondition[stakeType].duration ){

            if(_stakeCondition[stakeType].duration>0){
                delta = _stakeCondition[stakeType].duration;
            }

            _curStakeIds[stakeType][msg.sender].remove(tokenId);
            _erc721.safeTransferFrom(address(this), msg.sender, tokenId);

            sInfo.startTime = 0;
            uint256 reward = (_stakeCondition[stakeType].rewardRate*delta/10000).add(delta);
            sInfo.accumulateTime = sInfo.accumulateTime.add(reward);

            emit eWithdraw(tokenId, msg.sender, stakeType, reward, block.timestamp);
        }
    }


    function pause() public onlyOwner{
        if(paused()){
            _pause();
        }
        else{
            _unpause();
        }
    }

}