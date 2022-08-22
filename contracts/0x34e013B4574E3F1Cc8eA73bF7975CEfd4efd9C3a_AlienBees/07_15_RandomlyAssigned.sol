// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./WithLimitedSupply.sol";
abstract contract RandomlyAssigned is WithLimitedSupply {
    mapping(uint256 => uint256) private tokenMatrix;
    uint256 private startFrom;
    constructor (uint256 _totalSupply, uint256 _startFrom) WithLimitedSupply(_totalSupply){
        startFrom = _startFrom;
    }
    function nextToken() internal override ensureAvailability returns (uint256) {
        uint256 maxIndex = totalSupply() - tokenCount();
        uint256 random = uint256(keccak256(abi.encodePacked(msg.sender, block.coinbase, block.difficulty, block.gaslimit, block.timestamp))) % maxIndex;
        uint256 value;
        if (tokenMatrix[random] == 0) {
            value = random;
        } else {
            value = tokenMatrix[random];
        }
        if (tokenMatrix[maxIndex - 1] == 0) {
            tokenMatrix[random] = maxIndex - 1;
        } else {
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }
        super.nextToken();
        return value + startFrom;
    }
}