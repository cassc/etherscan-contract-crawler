// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMaidsToken.sol";

interface IMaidsNFT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract MaidsTokenYield is Ownable {
    // Events
    event Claim(address indexed to_, uint256[] tokenIds_, uint256 indexed totalClaimed_);

    // Interfaces
    IMaidsToken public Token; 
    IMaidsNFT public NFT;

    // Times
    uint256 public yieldStartTime = 1668610800; // 2022/11/17 00:00:00 GMT+0900
    uint256 public yieldEndTime = 1767193199; // 2025/12/31 23:59:59 GMT+0900

    // Rate
    uint256 public rate;

    // Yield Database
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;

    constructor(address token_, address nft_)  {
        rate = 10;
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

    function setRate(uint256 newRate) external onlyOwner {
        rate = newRate;
    }

    // Internal Calculators
    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        return tokenToLastClaimedTimestamp[tokenId_] < yieldStartTime ? yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
    }
    
    function _getCurrentTimeOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? block.timestamp : yieldEndTime;
    }

    // Yield Accountants
    function getPendingTokens(address address_, uint256 tokenId_) public view returns (uint256) {      
        if (address_ != NFT.ownerOf(tokenId_)) revert("You are not the owner!");

        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        return (_timeElapsed * rate * 1 ether) / 1 days;
    }

    function getPendingTokensMany(address address_, uint256[] memory tokenIds_) public view returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i; i < tokenIds_.length;) {
            _pendingTokens += getPendingTokens(address_, tokenIds_[i]);
            unchecked{ i++; }
        }
        return _pendingTokens;
    }
   
    // Internal Timekeepers
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();
        for (uint256 i; i < tokenIds_.length;) {
            if (tokenToLastClaimedTimestamp[tokenIds_[i]] == _timeCurrentOrEnded) revert("Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
            unchecked{ i++; }
        }
    }

    // Public Claim
    function claim(uint256[] calldata tokenIds_) external returns (uint256) {
        uint256 _pendingTokens = getPendingTokensMany(msg.sender, tokenIds_);
        
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
        for (uint256 i; i < _loopThrough; i++) {
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
        return getPendingTokensMany(address_, _tokenIds);
    }
}