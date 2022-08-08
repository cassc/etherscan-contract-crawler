//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Kitsune.sol";
import "./interfaces/IRoninViewer.sol";
import "./interfaces/IRoninPartial.sol";

contract KitsuneViewer{

    IRoninPartial ronin;
    Kitsune kitsune;
    IRoninViewer roninViewer;

    constructor(address _kitsune, address _ronin, address _roninViewer){
        ronin = IRoninPartial(_ronin);
        kitsune = Kitsune(_kitsune);
        roninViewer = IRoninViewer(_roninViewer);
    }

    function unclaimed(uint start_index, uint limit) public view returns(uint[] memory){
        uint unclaimedTokens;
        uint balance = ronin.balanceOf(msg.sender);
        if(balance == 0){
            uint[] memory _unclaimed;
            return _unclaimed;
        }

        require(start_index < balance,"Invalid start index");
        uint sampleSize = balance - start_index;
        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        for(uint i = 0; i < sampleSize; i++){
            if(kitsune.claimable(ronin.tokenOfOwnerByIndex(msg.sender,i + start_index))){
                unclaimedTokens++;
            }
        }
        uint[] memory _tokenIds = new uint256[](unclaimedTokens);
        unclaimedTokens = 0;
        for(uint i = 0; i < sampleSize; i++){
            uint tokenId = ronin.tokenOfOwnerByIndex(msg.sender,i + start_index);
            if(kitsune.claimable(tokenId)){
                _tokenIds[unclaimedTokens] = tokenId;
                unclaimedTokens++;
            }
        }
        return _tokenIds;
    }




    function kitsunes(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = kitsune.totalSupply();
        uint _maxId = _totalSupply;
        if(_totalSupply == 0){
            uint[] memory _none;
            return _none;
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }
        uint[] memory _tokenIds = new uint256[](sampleSize);
        uint _tokenId = startId;
        for(uint i = 0; i < sampleSize; i++){
            try kitsune.ownerOf(_tokenId) returns (address owner) {
                owner;
                _tokenIds[i] = _tokenId;
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }


    function myKitsunes(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = kitsune.totalSupply();
        uint _myBalance = kitsune.balanceOf(msg.sender);
        uint _maxId = 8888;
        if(_totalSupply == 0 || _myBalance == 0){
            uint[] memory _none;
            return _none;
        }

        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        uint[] memory _tokenIds = new uint256[](_myBalance);

        uint _tokenId = startId;
        uint found = 0;
        for(uint i = 0; i < sampleSize; i++){
            try kitsune.ownerOf(_tokenId) returns (address owner) {
                if(msg.sender == owner){
                    _tokenIds[found++] = _tokenId;
                }
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }

    function contractState() external view returns(uint _roninSupply, uint _roninUnclaimed, bool _roninPaused, uint _kitsuneSupply, bool _kitsuneStarted){
        IRoninViewer.Phase phase;
        bool counting;
        uint time;
        uint blockNumber;

        (_roninSupply, _roninUnclaimed, phase, counting, time, _roninPaused, blockNumber) = roninViewer.contractState();
        _kitsuneSupply = kitsune.totalSupply();
        _kitsuneStarted = kitsune.started();

        return (_roninSupply, _roninUnclaimed, _roninPaused, _kitsuneSupply, _kitsuneStarted);

    }
    function myState() external view returns(uint _myRoninCount, uint _myRoninReserveCount, uint _myKitsuneCount){

        _myRoninCount = ronin.balanceOf(msg.sender);

        (uint24 blockNumber, uint16[] memory tokens) = ronin.reservation(msg.sender);
        blockNumber;
        _myRoninReserveCount = tokens.length;

        _myKitsuneCount = kitsune.balanceOf(msg.sender);

        return (_myRoninCount, _myRoninReserveCount, _myKitsuneCount);
    }

}