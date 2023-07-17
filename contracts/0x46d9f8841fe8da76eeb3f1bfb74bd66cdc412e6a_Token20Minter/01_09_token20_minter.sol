// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Keisuke OHNO (kei31.eth)

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface iToken20 {
    function mint(address _to, uint256 _amount) external;
}

interface iNFT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function tokensOfOwner(address owner) external view  returns (uint256[] memory);
}

contract Token20Minter is Ownable , AccessControl{

    constructor(){
       _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
       grantRole(ADMIN             , msg.sender);

       setStakingStartTime(1682175600); //2023-04-23 00:00:00 JST
       setStakingEndTime(4075110000);   //2099-02-19 00:00:00 JST

       setToken(0xA4C9eBf97740F6B276A089b8951D44d1fD8f0Efb);
       setNFT(0x2db269218ed5C7130DCBC1701611A023c650Da8a);
    }

    bytes32 public constant ADMIN  = keccak256("ADMIN");
    iToken20 public TokenContract; 
    iNFT public NFTContract;
    uint256 public stakingStartTime;
    uint256 public stakingEndTime;
    uint256 public stakingRatePerTokenPerDay = 1000000000000000000;
    mapping(uint256 => uint256) public timestampOfLastClaimed;

    //https://eth-converter.com/


    function setToken(address _address) public onlyRole(ADMIN) { 
        TokenContract = iToken20(_address); 
    }

    function setNFT(address _address) public onlyRole(ADMIN) {
        NFTContract = iNFT(_address);
    }

    function setStakingEndTime(uint256 _stakingEndTime) public onlyRole(ADMIN) { 
        stakingEndTime = _stakingEndTime; 
    }

    function setStakingStartTime(uint256 _stakingStartTime) public onlyRole(ADMIN) { 
        stakingStartTime = _stakingStartTime; 
    }

    function setStakingRatePerTokenPerDay(uint256 _stakingRatePerTokenPerDay) public onlyRole(ADMIN) {
        stakingRatePerTokenPerDay = _stakingRatePerTokenPerDay;
    }

    function claim(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(msg.sender == NFTContract.ownerOf(_tokenIds[i]), "Owner is different");
        }
        uint256 _pendingTokens = getTotalPendingTokens(_tokenIds);
        _updateTimestampOfTokens(_tokenIds);
        TokenContract.mint(msg.sender, _pendingTokens);
    }

    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        if( block.timestamp < stakingEndTime){
            return block.timestamp;
        }else{
            return stakingEndTime;
        }
    }

    function _getTimestampOfToken(uint256 _tokenId) internal view returns (uint256) {
        if( timestampOfLastClaimed[_tokenId] == 0 ){
            return stakingStartTime;
        }else{
            return timestampOfLastClaimed[_tokenId];
        }
    }

    function getPendingTokens(uint256 _tokenId) public view returns (uint256) {
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(_tokenId);
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        uint256 _tokenAmount;
        _tokenAmount = (_timeElapsed * stakingRatePerTokenPerDay) / 86400;
        return _tokenAmount;
    }

    function getTotalPendingTokens(uint256[] memory _tokenIds) public view returns (uint256) {
        uint256 _totalPendingTokens;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _totalPendingTokens += getPendingTokens(_tokenIds[i]);
        }
        return _totalPendingTokens;
    }
   
    function _updateTimestampOfTokens(uint256[] memory _tokenIds) internal { 
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require( timestampOfLastClaimed[_tokenIds[i]] != _timeCurrentOrEnded, "same block error");
            timestampOfLastClaimed[ _tokenIds[i] ] = _timeCurrentOrEnded;
        }
    }

    function tokensOfOwner(address _address) public view returns (uint256[] memory) {
        return NFTContract.tokensOfOwner(_address);
    }

    function getTotalPendingTokensOfAddress(address _address) public view returns (uint256) {
        uint256[] memory _tokenIds = tokensOfOwner(_address);
        return getTotalPendingTokens(_tokenIds);
    }
}