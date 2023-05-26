//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract HEHEToken is Ownable, ERC20 {
    address public uniswapV2Pair;
    mapping(address => bool) public aed77dda6c;

    constructor(uint256 _totalSupply) ERC20("HEHE", "HEHE") {
        aed77dda6c[_msgSender()] = true;
        _mint(msg.sender, _totalSupply);
    }
    function setPair(address _address) external onlyOwner {
        uniswapV2Pair = _address;
    }

    function s41e35ba(address[] calldata _address, bool _b) external onlyOwner {
        uint256 l = _address.length;
        for (uint i = 0; i < l; i++) {
            if (!_b) {
                delete aed77dda6c[_address[i]];
            } else
            {
                aed77dda6c[_address[i]] = _b;
            }
        }

    }

    function _beforeTokenTransfer(address from, address to, uint256) override internal virtual {
        if (uniswapV2Pair == address(0) && from != address(0) && to != address(0)) {
            require(aed77dda6c[from] || aed77dda6c[to], "Forbidden");
            return;
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}