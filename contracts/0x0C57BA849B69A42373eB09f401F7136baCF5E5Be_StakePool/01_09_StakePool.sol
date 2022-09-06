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

contract StakePool is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public _erc721;
    uint256 public _stakeLimit;

    struct stakeInfo{
        uint256 startTime;
        uint256 accumulateTime;
    }

    struct stakeRecord{
        uint256 tokenId;
        uint256 accumulateTime;
        uint256 extraTime;
    }

    mapping(address => mapping( uint256 => stakeInfo )) public _stakeInfos; //address=>tokenid=>stakeInfo
    mapping(address => EnumerableSet.UintSet) private _recordStakeIds;  // address=>tokenids;
    mapping(address => EnumerableSet.UintSet) private _curStakeIds;  // address=>tokenids;

    event eStake( uint256[] tokenId, address owner );
    event eWithdraw( uint256[] tokenId, address owner);

    constructor(IERC721 erc721, uint256 stakeLimit) {
        _erc721 = erc721;
        _stakeLimit = stakeLimit;
    }

    function onERC721Received(address /*operator*/ , address /*from*/ , uint256 /*tokenId*/, bytes calldata  /*data*/) external pure returns (bytes4) {
        // if( paused ) {
        //     return 0;
        // }
        return this.onERC721Received.selector;
    }

    function getCurStakeTokens(address owner) public view returns(uint256[] memory ){
        return _curStakeIds[owner].values();
    }

    function getRecordStakeTokens(address owner) public view returns(uint256[] memory ){
        return _recordStakeIds[owner].values();
    }

    function getStakeInfo(address owner) public view returns(stakeRecord[] memory ){

        uint256[] memory tokenIds  = _recordStakeIds[owner].values();

        stakeRecord[] memory records = new stakeRecord[](tokenIds.length);
        for( uint256 i=0; i<tokenIds.length; i++){
            records[i].tokenId = tokenIds[i];
            records[i].accumulateTime = _stakeInfos[owner][tokenIds[i]].accumulateTime;
            if(_stakeInfos[owner][tokenIds[i]].startTime==0){
                records[i].extraTime=0;
            }
            else{
                records[i].extraTime = block.timestamp.sub(_stakeInfos[owner][tokenIds[i]].startTime);
            }
            
        }

        return records;
    }

    function setErc721(IERC721 erc721) public onlyOwner{
        _erc721 = erc721;
    }
    
    function setLimit(uint256 limit) public onlyOwner{
        _stakeLimit = limit;
    }

    function stakeNFTs(uint256[] calldata nftList) public whenNotPaused nonReentrant {

        uint256 stakeAmount = nftList.length+_curStakeIds[msg.sender].length();
        require( stakeAmount <= _stakeLimit, "stake amount over limit! " );

        for( uint256 i=0; i<nftList.length; i++){

            _erc721.safeTransferFrom(msg.sender, address(this), nftList[i]);
        
            _curStakeIds[msg.sender].add(nftList[i]);
            _recordStakeIds[msg.sender].add(nftList[i]);

            // _stakeInfos[msg.sender][nftList[i]].tokenId = nftList[i];
            _stakeInfos[msg.sender][nftList[i]].startTime=block.timestamp;

        }

        emit eStake(nftList, msg.sender);
    
    }

    function withdrawNFTs(uint256[] calldata nftList) public whenNotPaused nonReentrant {

        uint256 tokenId = 0;

        for (uint256 i = 0; i<nftList.length; i++) {

            tokenId = nftList[i];
            _curStakeIds[msg.sender].remove(tokenId);
            _erc721.safeTransferFrom(address(this), msg.sender, tokenId);

            uint256 delta = block.timestamp.sub(_stakeInfos[msg.sender][tokenId].startTime);
            _stakeInfos[msg.sender][tokenId].startTime = 0;
            _stakeInfos[msg.sender][tokenId].accumulateTime += delta;
        }
        emit eWithdraw(nftList, msg.sender);
    }

    function withdrawAll() public whenNotPaused nonReentrant {

        uint256[] memory ids = _curStakeIds[msg.sender].values();
        uint256 tokenId = 0;

        require(ids.length>0,"there are not any nfts staking");

        for (uint256 i = 0; i <ids.length; i++) {

            tokenId = ids[i];
            _curStakeIds[msg.sender].remove(tokenId);
            _erc721.safeTransferFrom(address(this), msg.sender, tokenId);

            uint256 delta = block.timestamp.sub(_stakeInfos[msg.sender][tokenId].startTime);
            _stakeInfos[msg.sender][tokenId].startTime = 0;
            _stakeInfos[msg.sender][tokenId].accumulateTime += delta;
        }

        emit eWithdraw(ids, msg.sender);
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