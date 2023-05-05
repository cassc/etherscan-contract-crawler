// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./Wrap.sol";

abstract contract Swapable is Ownable {
    IUniswapV2Router02 public immutable router;

    mapping(address => bool) public pairs;

    constructor(address _router, address[] memory _tokens) {
        router = IUniswapV2Router02(_router);
        address factory = router.factory();
        for (uint i = 0; i < _tokens.length; i++) {
            address pair = IUniswapV2Factory(factory).createPair(address(this), _tokens[i]);
            pairs[pair] = true;
        }
    }

    function addPair(address pair) public onlyOwner {
        pairs[pair] = true;
    }

    function delPair(address pair) public onlyOwner {
        pairs[pair] = false;
    }

    function isPair(address pair) public view returns (bool) {
        return pairs[pair];
    }
}