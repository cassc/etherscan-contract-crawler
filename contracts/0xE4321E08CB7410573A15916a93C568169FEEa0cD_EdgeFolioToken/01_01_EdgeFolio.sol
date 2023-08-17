// SPDX-License-Identifier: MIT
/*

In the same way that AI revolutionized content creation, Edgefolio is revolutionizing DeFi profitability 
by way of automated and managed distribution. Large institutional fund managers make it near impossible 
for the average crypto investor to benefit from fund appreciation due to high entry barriers and long-term investment approaches
in blue-chip coins. Edgefolio and the introduction of EdgeFund marks the beginning of a new age for DeFi profit sharing
that provides regular ETH dividends to NFT and Token holders.

Twitter:  https://twitter.com/edgefolioeth
Telegram: http://t.me/EdgefolioETH
Web:      https://edgefolioeth.com

*/

pragma solidity 0.8.21;

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
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface IUniswapV2Router02 {
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

contract EdgeFolioToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address payable public _marketingWallet;
    address payable public _edgeFundWallet;
    address public _edgeStakingContract;

    // After removing limits, final tax values
    uint256 private _finalBuyTax = 2;
    uint256 private _finalSellTax = 2;

    uint256 public buyTax = 10;
    uint256 public sellTax = 20;

    string private constant _name = "Edge Folio";
    string private constant _symbol = "EDGE";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool public tradingEnabled;
    bool private inSwap;
    bool private swapEnabled;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100e6 * 10**_decimals;

    uint256 public maxWalletSize = _tTotal * 2 / 100;
    uint256 _minTokensBeforeSwap = _tTotal / 200;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _marketingWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingEnabled, "Can't trade");
            
            if (from == uniswapV2Pair) {
                taxAmount = amount * buyTax / 100;
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds max wallet size!");
            }

            if(to == uniswapV2Pair ){
                taxAmount = amount * sellTax / 100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _minTokensBeforeSwap) {
                swapBack(_minTokensBeforeSwap);
            }
        }

        if(taxAmount > 0){
          _balances[address(this)] += taxAmount;
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from] -= amount;
        _balances[to] += amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    function removeLimits() external onlyOwner{
        maxWalletSize =_tTotal;
        buyTax = _finalBuyTax;
        sellTax = _finalSellTax;
    }

    function swapBack(uint256 amount) private {        
        bool success;
        swapTokensForEth(amount);
        uint256 ethBalance = address(this).balance;
        (success, ) = address(_edgeFundWallet).call{value: ethBalance / 2}("");
        (success, ) = address(_marketingWallet).call{value: address(this).balance}("");
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function setSwapTokensAtAmount(uint amt) external onlyOwner {
        _minTokensBeforeSwap = amt * 10 ** decimals();
    }

    function excludeFromFees(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFees(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        require(wallet != address(0), "Can't set 0 address");
        _marketingWallet = wallet;
    }

    function setEdgeFundWallet(address payable wallet) external onlyOwner {
        require(wallet != address(0), "Can't set 0 address");
        _edgeFundWallet = wallet;
    }

    function setEdgeStakingContract(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Can't set 0 address");
        _edgeStakingContract = _stakingContract;
        _isExcludedFromFee[_stakingContract] = true;
    }

    function enableTrading() external onlyOwner() {
        require(!tradingEnabled,"trading is already open");
        swapEnabled = true;
        tradingEnabled = true;
    }

    receive() external payable {}
}