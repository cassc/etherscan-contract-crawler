// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CountHash is Ownable {
    uint public totalFlags;
    mapping(address => bool) public isComm;
    mapping(string => uint) public totalHashs;

    modifier onlyComm() {
        isComm[_msgSender()] == true;
        _;
    }
    constructor() {}
    function setIsComm(address _comm, bool _enable) external onlyOwner {
        isComm[_comm] = _enable;
    }
    function addHash(string memory hash) external onlyComm {
        totalHashs[hash]++;
        totalFlags++;
    }

    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}