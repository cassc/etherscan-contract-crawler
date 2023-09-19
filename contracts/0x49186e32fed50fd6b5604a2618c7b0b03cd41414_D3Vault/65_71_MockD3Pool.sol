// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract MockD3Pool {
    address public _CREATOR_;
    uint256 public allFlag;
    
    constructor() {
        _CREATOR_ = msg.sender;
    }

    function setNewAllFlag(uint256 newFlag) public {
        allFlag = newFlag;
    }

    function getFeeRate(address token) public pure returns(uint256){
        return 2 * (10 ** 14);
    }

    function testSuccess() public {}
}