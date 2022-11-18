// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMaidsToken.sol";

interface IMaidsNFT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract MaidsTokenYield is Ownable {
    using Strings for uint256;

    // claim token per day
    struct yieldRate {
        uint256 day;
        uint256 rate;
    }

    // Events
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);

    // Interfaces
    IMaidsToken public Token; 
    IMaidsNFT public NFT;

    // Times
    uint256 public yieldStartTime = 1668610800; // 2022/11/17 00:00:00 GMT+0900
    uint256 public yieldEndTime = 1767193199; // 2025/12/31 23:59:59 GMT+0900

    // Yield Info
    yieldRate[] private yieldRateData;

    // Yield Database
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;

    constructor(address token_, address nft_)  {
        yieldRateData.push(yieldRate(0, 10));
        Token = IMaidsToken(token_);
        NFT = IMaidsNFT(nft_);
    }

    function renounceOwnership() public override onlyOwner {}
    
    function setToken(address address_) external onlyOwner { 
        Token = IMaidsToken(address_); 
    }

    function setNFT(address address_) external onlyOwner {
        NFT = IMaidsNFT(address_);
    }

    function setYieldStartTime(uint256 yieldStartTime_) external onlyOwner { 
        yieldStartTime = yieldStartTime_;
    }

    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_;
    }

    function setYieldRateData(uint256 day_, uint256 rate_) external onlyOwner {
        for (uint256 i = 0; i < yieldRateData.length; i++) {
            yieldRate storage data = yieldRateData[i];
            if (data.day == day_) {
                data.rate = rate_;
                return;
            }
        }
        yieldRateData.push(yieldRate(day_, rate_));
    }

    function getYieldRateData() external view returns (string memory) {
        bytes memory ret = abi.encodePacked('[');

        for (uint256 i = 0; i < yieldRateData.length; i++) {
            if (i!=0) { ret = abi.encodePacked(ret, ','); }

            yieldRate memory data = yieldRateData[i];
            ret = abi.encodePacked(ret,
                '{',
                '"day": ',
                data.day.toString(),
                ', "rate": ',
                data.rate.toString(),
                '}');
        }

        ret = abi.encodePacked(ret, ']');
        return string(ret);
    }

    // Internal Calculators
    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        return tokenToLastClaimedTimestamp[tokenId_] < yieldStartTime ? yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
    }
    
    function _getCurrentTimeOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? block.timestamp : yieldEndTime;
    }

    function _getYieldRate(uint256 day_) internal view returns (uint256) {
        uint256 rate = 0;
        for (uint256 i = 0; i < yieldRateData.length; i++) {
            yieldRate memory data = yieldRateData[i];
            if (data.day <= day_ && rate < data.rate) {
                rate = data.rate;
            }
        }
        return rate * 1 ether;
    }

    // Yield Accountants
    function getPendingTokens(uint256 tokenId_) public view returns (uint256) {        
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        uint256 rate = _getYieldRate((_timeElapsed / 1 days));
        return (_timeElapsed * rate) / 1 days;
    }

    function getPendingTokensMany(uint256[] memory tokenIds_) public view returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }
   
    // Internal Timekeepers
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (tokenToLastClaimedTimestamp[tokenIds_[i]] == _timeCurrentOrEnded) revert("Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    // Public Claim
    function claim(uint256[] calldata tokenIds_) public returns (uint256) {
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        
        _updateTimestampOfTokens(tokenIds_);

        Token.mint(msg.sender, _pendingTokens);

        emit Claim(msg.sender, tokenIds_, _pendingTokens);

        return _pendingTokens;
    } 
    
    // Public View Functions for Helpers
    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = NFT.balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = NFT.totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            address _ownerOf = NFT.ownerOf(i);
            if (_ownerOf == address(0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (_ownerOf == address_) {
                _tokens[_index++] = i;
            }
        }
        return _tokens;
    }

    function getPendingTokensOfAddress(address address_) public view returns (uint256) {
        uint256[] memory _tokenIds = walletOfOwner(address_);
        return getPendingTokensMany(_tokenIds);
    }
}