// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../swap/BabyFactory.sol';
import './Oracle.sol';

contract OracleCaller is Ownable {
    
    event Update(address tokenA, address tokenB);

    Oracle oracle;
    uint constant CRYCLE = 30 minutes;
    BabyFactory factory;

    function setOracle(Oracle _oracle) external {
        oracle = _oracle;
    }

    function setFactory(BabyFactory _factory) external {
        factory = _factory;
    }

    constructor(Oracle _oracle, BabyFactory _factory) {
        oracle = _oracle;
        factory = _factory;
    }

    address[] tokenA;
    address[] tokenB;
    address[] pairs;
    mapping(address => bool) pairMap;
    mapping(address => uint) timestamp;

    function pairExists(address pair) external view returns(bool) {
        return pairMap[pair];
    }

    function pairLength() external view returns (uint) {
        return pairs.length;
    }

    function addPair(address _tokenA, address _tokenB) external onlyOwner {
        address pair = factory.expectPairFor(_tokenA, _tokenB);
        require(!pairMap[pair], "pair already exist");
        tokenA.push(_tokenA);
        tokenB.push(_tokenB);
        pairs.push(pair);
        pairMap[pair] = true;
    }

    function delPair(uint _id) external onlyOwner {
        require(_id < tokenA.length && tokenA.length != tokenB.length, "illegal id");
        uint lastIndex = tokenA.length - 1;
        if (lastIndex > _id) {
            tokenA[_id] = tokenA[lastIndex];
            tokenB[_id] = tokenB[lastIndex];
            pairs[_id] = pairs[lastIndex];
        }
        tokenA.pop();
        tokenB.pop();
        pairs.pop();
    }

    function update() external {
        uint current = block.timestamp;
        for(uint i = 0; i < tokenA.length; i ++) {
            if (current - timestamp[pairs[i]] < CRYCLE) {
                continue;
            }
            oracle.update(tokenA[i], tokenB[i]);
            //timestamp[pairs[i]] = current;
            //emit Update(tokenA[i], tokenB[i]);
        }
    }

    function updateTokens(address[] memory tokens, address base) external {
        for (uint i = 0; i < tokens.length; i ++) {
            oracle.update(tokens[i], base);
        }
    }
}