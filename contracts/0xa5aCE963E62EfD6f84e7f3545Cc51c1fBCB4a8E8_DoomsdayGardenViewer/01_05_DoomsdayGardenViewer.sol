// SPDX-License-Identifier: Hermit crabs only
pragma solidity ^0.8.9;

import "./DoomsdayGarden.sol";

contract DoomsdayGardenViewer {
    DoomsdayGarden garden;
    constructor(address _garden){
        garden = DoomsdayGarden(_garden);
    }

    function contractState() public view returns(
        uint harvested,
        uint ownerWithdrawn,
        bytes32 lastHash,
        uint totalSupply,
        uint blockNumber
    ){
        return (
            garden.harvested(),
            garden.ownerWithdrawn(),
            garden.getLastHash(),
            garden.totalSupply(),block.number);
    }

    function getTokenData(uint startId, uint limit)  public view returns(uint[] memory _tokenIds, bytes32[] memory _hashes,uint[] memory _supplyAtMint, uint blockNumber){
        uint _totalSupply = garden.totalSupply();

        uint _maxId = _totalSupply + garden.harvested();


        if(_totalSupply == 0){
            uint[] memory _noneUint;
            bytes32[] memory _noneBytes32;

            return (_noneUint,_noneBytes32,_noneUint,block.number);
        }

        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        _tokenIds     = new uint256[](sampleSize);
        _hashes    = new bytes32[](sampleSize);
        _supplyAtMint = new uint256[](sampleSize);

        uint _tokenId = startId;
        for(uint i = 0; i < sampleSize; i++){
            try garden.treeData(_tokenId) returns (bytes32 __hash, uint __supplyAtMint, uint __planted) {
                __planted;

                _tokenIds[i] = _tokenId;
                _hashes[i] = __hash;
                _supplyAtMint[i] = __supplyAtMint;
            } catch {

            }
            _tokenId++;
        }
        return (_tokenIds, _hashes, _supplyAtMint, block.number);


    }


    function myTrees(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = garden.totalSupply();

        uint _myBalance = garden.balanceOf(msg.sender);

        uint _maxId = _totalSupply + garden.harvested();

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
            try garden.ownerOf(_tokenId) returns (address owner) {
                if(msg.sender == owner){
                    _tokenIds[found++] = _tokenId;
                }
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }
}