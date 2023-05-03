// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./pancake/interfaces/IUniswapV2Factory.sol";
import "./pancake/interfaces/IUniswapV2Router02.sol";
import "./pancake/interfaces/IUniswapV2Pair.sol";
import "./TmpStorage.sol";
import "./lib/ITokenB.sol";

contract ZeroFaucet is ERC20, Ownable{

    string private _name = 'ZeroFaucet';
    string private _symbol = 'ZeroFaucet';

    mapping (address => mapping(address => bool)) public _transferMap;
    mapping (address => address) public _parentMap;

    constructor () ERC20 (_name, _symbol) {}

    function _transfer(
        address from,
        address to,
        uint amount
    ) internal override {
        if (_parentMap[from] == address(0) && _transferMap[to][from] == true) {
            _parentMap[from] = to;
        } else if (_parentMap[to] == address(0)) {
            _transferMap[from][to] = true;
        }
        super._transfer(from, to, amount);
    }

    function mint() public {
        _mint(msg.sender, 100 ether);
    }
}