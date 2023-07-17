// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
// import "hardhat/console.sol";

contract APENOUT is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;

    APENOUTDividendTracker public dividendTracker;

    uint256 public swapTokensAtAmount = 200000 * (10**18);

    uint256 public constant taxIn = 10;
    uint256 public constant taxOut = 30;

    uint256 public constant ethRewardsFee = 70;
    uint256 public constant devFee = 10;
    uint256 public constant marketingFee = 10;
    uint256 public constant buyBackFee = 10;
    uint256 public constant totalFee = 100;

    address payable devAddress = payable(0x82B6c2499d2b5170dE86aF1492D8E8F5026E4ae5);
    address payable buyBackAddress = payable(0x3Ba091BDD1d500b37F43bEA198976EecD0eF02A0);
    address payable marketingAddress = payable(0xf548B5eA73a7d5fbb9C4Fb6be6040F790E4B6e62);

    uint256 public tradingEnabledTimestamp = 1657685042;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    mapping (uint256 => mapping(address => uint256)) public dailyTransfers;

    mapping(uint256 => uint256) public maxDailySells;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("APENOUT", "APENOUT") {
    	dividendTracker = new APENOUTDividendTracker();
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // enable owner to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;

        maxDailySells[0] = 100000 * (10**18);
        maxDailySells[1] = 100000 * (10**18);
        maxDailySells[2] = 400000 * (10**18);
        maxDailySells[3] = 500000 * (10**18);
        maxDailySells[4] = 1000000 * (10**18);
        maxDailySells[5] = 1500000 * (10**18);
        maxDailySells[6] = 2000000 * (10**18);
        maxDailySells[7] = 2500000 * (10**18);
        maxDailySells[8] = 3000000 * (10**18);
        maxDailySells[9] = 3500000 * (10**18);
        maxDailySells[10] = 4000000 * (10**18);
        maxDailySells[11] = 8000000 * (10**18);

        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {

  	}
    
  	function setTradingStartTime(uint256 _tradingEnabledTimestamp) public onlyOwner {
  	    require(tradingEnabledTimestamp > block.timestamp, "APENOUT: Trading has already started");
  	    require(_tradingEnabledTimestamp > block.timestamp, "APENOUT: Start time must be in the future");
  	    tradingEnabledTimestamp = _tradingEnabledTimestamp;
  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "APENOUT: The dividend tracker already has that address");

        APENOUTDividendTracker newDividendTracker = APENOUTDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "APENOUT: The new dividend tracker must be owned by the APENOUT token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(address(uniswapV2Pair));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "APENOUT: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        dividendTracker.excludeFromDividends(address(uniswapV2Router));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "APENOUT: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function allowPreTrading(address account, bool allowed) public onlyOwner {
        // used for owner and pre sale addresses
        require(canTransferBeforeTradingIsEnabled[account] != allowed, "APENOUT: Pre trading is already the value of 'excluded'");
        canTransferBeforeTradingIsEnabled[account] = allowed;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "APENOUT: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "APENOUT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setDevAddress(address payable _devAddress) external {
        require(msg.sender == devAddress, "APENOUT: sender must be devAddress");
        devAddress = _devAddress;
    }

    function setMarketingAddress(address payable _marketingAddress) external {
        require(msg.sender == marketingAddress, "APENOUT: sender must be marketingAddress");
        marketingAddress = _marketingAddress;
    }

    function setBuyBackAddress(address payable _buyBackAddress) external onlyOwner {
        buyBackAddress =_buyBackAddress;
    }

    function setMinimumTokenBalanceForDividends(uint256 _minimumTokenBalanceForDividends) external onlyOwner {
        dividendTracker.setMinimumTokenBalanceForDividends(_minimumTokenBalanceForDividends);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            uint256,
            uint256,
            uint256
        ) {
        return dividendTracker.getAccount(account);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender));
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function getMaxTxFrom() internal view returns (uint256) {
        uint256 daysSinceLaunch = block.timestamp.sub(tradingEnabledTimestamp).div(1 days);
        uint256 maxSell = maxDailySells[daysSinceLaunch];
        if (maxSell == 0) {
            return totalSupply();
        }
        return maxSell;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        bool tradingIsEnabled = getTradingIsEnabled();
        bool isBuying = automatedMarketMakerPairs[from];
        bool isSelling = automatedMarketMakerPairs[to];

        if(!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "APENOUT: This account cannot send tokens until trading is enabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // make sure that the sender has not exceeded their daily transfer limit
        // automated market pairs do not have a daily transfer limit
        if (!_isExcludedFromFees[from] && !automatedMarketMakerPairs[from]) {
            uint256 maxTxFrom = getMaxTxFrom();
            uint256 day = block.timestamp.div(1 days).add(1);
            require(dailyTransfers[day][from].add(amount) <= maxTxFrom, "APENOUT: This account has exceeded max daily limit");
            dailyTransfers[day][from] = dailyTransfers[day][from].add(amount);
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            tradingIsEnabled && 
            canSwap &&
            !swapping &&
            isSelling
        ) {
            swapping = true;
            distributeEth(contractTokenBalance, 0);
            swapping = false;
        }

        bool takeTax = (isSelling || isBuying) && !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to];

        if(takeTax) {
        	uint256 tax = isBuying ? amount.mul(taxIn).div(100) : amount.mul(taxOut).div(100);
        	amount = amount.sub(tax);
            super._transfer(from, address(this), tax);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
    }

    // function used to liquidate tokens held by contract in the event that the contract holds too many tokens
    function liquidateContractTokens(uint256 tokenAmount, uint256 amountOutMin) external {
        uint256 contractBalance = balanceOf(address(this));
        require(tokenAmount <= contractBalance, "APENOUT: Insufficient token balance");
        distributeEth(tokenAmount, amountOutMin);
    }

    function distributeEth(uint256 tokenAmount, uint256 amountOutMin) internal {
        swapTokensForEth(tokenAmount, amountOutMin);

        uint256 ethAmount = address(this).balance;
        uint256 rewardAlloc = ethAmount.mul(ethRewardsFee).div(totalFee);
        uint256 gasAlloc = ethAmount.mul(buyBackFee).div(totalFee);
        uint256 devAlloc = ethAmount.mul(devFee).div(totalFee);
        uint256 marketingAlloc = ethAmount.sub(rewardAlloc).sub(gasAlloc).sub(devAlloc);
        
        address(dividendTracker).call{value: rewardAlloc}("");
        buyBackAddress.call{value: gasAlloc}("");
        devAddress.call{value: devAlloc}("");
        marketingAddress.call{value: marketingAlloc}("");
    }

    function swapTokensForEth(uint256 tokenAmount, uint256 amountOutMin) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }
}

contract APENOUTDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);

    constructor() DividendPayingToken() {
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }

    function setMinimumTokenBalanceForDividends(uint256 _minimumTokenBalanceForDividends) external onlyOwner {
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);

    	emit ExcludeFromDividends(account);
    }

    function getAccount(address _account)
        public view returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 withdrawnDividends
        ) {
        account = _account;
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        withdrawnDividends = withdrawnDividendOf(account);
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    	}

    	processAccount(account);
    }

    function processAccount(address payable account) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
    	if(amount > 0) {
    		return true;
    	}

    	return false;
    }
}