// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/math/SafeMath.sol";
import "./interface/IUniswapV2Pair.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router.sol";

interface IHustleDividendTracker {
    function mint(address shareholder, uint256 amount) external;

    function burn(address shareholder, uint256 amount) external;

    function withdrawDividendOfUserAsToken(address shareholder, address tokenAddress) external;
}

contract HustleToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    IHustleDividendTracker public dividendTracker;

    uint256 public maxSellTransactionAmount = 500000000 * 10 ** decimals();
    uint256 public swapTokensAtAmount = 2000000 * 10 ** decimals();
    uint256 public maxWalletSize = 500000000 * 10 ** decimals();

    uint256 public swapCooldown = 10 minutes;
    uint256 public lastSwapTimestamp;

    uint256 public ETHRewardFee = 2;
    uint256 public liquidityFee = 1;
    uint256 public maintenanceFee = 2;

    uint256 public totalFees = ETHRewardFee.add(liquidityFee).add(maintenanceFee);

    address payable _maintenanceWallet;
    address payable _LPWallet;
    uint64 private _startTradingAt;
    uint32 private _maxGasPriceGwei = 60;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isDisallowed;
    mapping(address => bool) private _isPresaleDistributor;
    mapping(address => bool) public automatedMarketMakerPairs;

    bool private swapping;
    bool private reinvesting;
    bool public confirmedLaunch;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event NewMaintenanceWallet(address indexed newMaintenanceWallet, address indexed oldMaintenanceWallet);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    constructor(address _routerAddress, address payable _dividendTracker) ERC20("HustleBot", "Hustle") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);

        address _uniswapV2Pair =
            IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        dividendTracker = IHustleDividendTracker(_dividendTracker);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        _maintenanceWallet = payable(owner());
        _LPWallet = payable(owner());

        _mint(owner(), 10_000_000_000 * (10 ** 18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(dividendTracker), "HSTL: The dividend tracker already has that address");

        IHustleDividendTracker newDividendTracker = IHustleDividendTracker(payable(newAddress));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "HSTL: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updateUniswapV2Pair(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Pair), "HSTL: The pair already has that address");
        uniswapV2Pair = newAddress;
    }

    function setMaintenance(uint256 newMaintenanceFee, address payable newMaintenanceWallet) external onlyOwner {
        require(newMaintenanceFee <= 5, "Maximum fee limit is 5 percent");
        emit NewMaintenanceWallet(newMaintenanceWallet, _maintenanceWallet);
        maintenanceFee = newMaintenanceFee;
        _maintenanceWallet = newMaintenanceWallet;
        _isExcludedFromFees[_maintenanceWallet] = true;
        totalFees = ETHRewardFee.add(liquidityFee).add(maintenanceFee);
    }

    function confirmLaunch() external onlyOwner {
        confirmedLaunch = true;
    }

    function setIsDisallowed(address account, bool value) external onlyOwner {
        _isDisallowed[account] = value;
    }

    function setMaxGasPriceGwei(uint32 newMaxGasPriceGwei) external onlyOwner {
        _maxGasPriceGwei = newMaxGasPriceGwei;
    }

    function setIsPresaleDistributor(address account, bool value) external onlyOwner {
        _isPresaleDistributor[account] = value;
    }

    function setAreDisallowed(address[] calldata accounts, bool value) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isDisallowed[accounts[i]] = value;
        }
    }

    function setLPWallet(address payable newLPWallet) external onlyOwner {
        require(newLPWallet != address(_LPWallet), "HSTL: The LPWallet already has that address");
        emit LiquidityWalletUpdated(newLPWallet, _LPWallet);
        _LPWallet = newLPWallet;
    }

    function setSwapCooldown(uint256 newSwapCooldown) external onlyOwner {
        swapCooldown = newSwapCooldown;
    }

    function setAmountToInitiateSwap(uint256 newSwapThreshold) external onlyOwner {
        require(
            totalFees.mul(100) * 10 ** decimals() <= newSwapThreshold,
            "Threshold to initiate swap should be minimum equal to 100*totalFees"
        );

        swapTokensAtAmount = newSwapThreshold;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "HSTL: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
            emit ExcludeFromFees(accounts[i], excluded);
        }
    }

    function setETHRewardFee(uint256 newETHRewardFee) external onlyOwner {
        require(newETHRewardFee <= 10, "Maximum fee limit is 10 percent");
        ETHRewardFee = newETHRewardFee;
        totalFees = ETHRewardFee.add(liquidityFee).add(maintenanceFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner {
        require(value <= 5, "Maximum fee limit is 5 percent");
        liquidityFee = value;
        totalFees = ETHRewardFee.add(liquidityFee).add(maintenanceFee);
    }

    function setMaxSellTxAmount(uint256 amount) external onlyOwner {
        require(amount >= 500000 * 10 ** decimals(), "Max sells can't be lower than 500 000 HSTL");
        maxSellTransactionAmount = amount;
    }

    function setMaxWalletSize(uint256 amount) external onlyOwner {
        require(amount >= 500000 * 10 ** decimals(), "Max wallet size can't be lower than 500 000 HSTL");
        maxWalletSize = amount;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "HSTL: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value, "HSTL: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setStartTradingAt(uint64 blocknumber) external onlyOwner {
        require(!confirmedLaunch, "HSTL: Already launched");
        _startTradingAt = blocknumber;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (_startTradingAt == 0 || _startTradingAt > block.number) {
            require(
                _isExcludedFromFees[tx.origin] || _isExcludedFromFees[msg.sender] || _isExcludedFromFees[from],
                "HSTL: Liquidity not added yet"
            );
            try dividendTracker.burn(from, amount) {} catch {}
            try dividendTracker.mint(to, amount) {} catch {}
            return super._transfer(from, to, amount);
        }

        if (block.number >= _startTradingAt && block.number <= _startTradingAt + 10) {
            require(tx.gasprice <= uint256(_maxGasPriceGwei) * 1 gwei, "HSTL: Gas price too high");
        }

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isDisallowed[to], "Disallowed wallet");

        if (to != owner() || to != address(this)) {
            require(!_isDisallowed[from], "Disallowed wallet");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        try dividendTracker.burn(from, amount) {} catch {}

        if (
            !swapping && automatedMarketMakerPairs[to] && from != address(uniswapV2Router) && !_isExcludedFromFees[from]
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !automatedMarketMakerPairs[to]) {
            require(balanceOf(to) + amount <= maxWalletSize, "Wallet limit exceeded");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount && block.timestamp >= lastSwapTimestamp + swapCooldown;

        if (canSwap && !swapping && !automatedMarketMakerPairs[from] && from != owner() && to != owner()) {
            swapping = true;
            lastSwapTimestamp = block.timestamp;
            swapAndLiquify(contractTokenBalance.mul(liquidityFee).div(totalFees));
            swapAndDistribute(balanceOf(address(this)));
            swapping = false;
        }

        bool buying = from == uniswapV2Pair && to != address(uniswapV2Router);
        bool selling = from != address(uniswapV2Router) && to == uniswapV2Pair;

        bool takeFee = !swapping && (buying || selling);

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        if (!_isPresaleDistributor[from]) try dividendTracker.mint(to, amount) {} catch {}
    }

    function reinvest() external {
        bool isExcluded = _isExcludedFromFees[msg.sender];
        if (!isExcluded) _isExcludedFromFees[msg.sender] = true;
        dividendTracker.withdrawDividendOfUserAsToken(msg.sender, address(this));
        if (!isExcluded) _isExcludedFromFees[msg.sender] = false;
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 halfOfLiquify = tokens.div(2);
        uint256 otherHalfOfLiquify = tokens.sub(halfOfLiquify);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(halfOfLiquify);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalfOfLiquify, newBalance);

        emit SwapAndLiquify(halfOfLiquify, newBalance, otherHalfOfLiquify);
    }

    function swapAndDistribute(uint256 tokens) private {
        swapTokensForEth(tokens);

        uint256 initialBalance = address(this).balance;

        uint256 toDistribute = initialBalance.mul(maintenanceFee).div(totalFees);
        _maintenanceWallet.transfer(toDistribute);

        toDistribute = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: toDistribute}("");

        if (success) {
            emit SendDividends(tokens, toDistribute);
        }
    }

    function manualSwapAndDistribute() external onlyOwner {
        uint256 tokens = balanceOf(address(this));
        swapAndDistribute(tokens);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function swapBnbForToken(uint256 ethAmount, address token, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, path, receiver, block.timestamp + 360
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, _LPWallet, block.timestamp);
    }

    function rescueEth(address to, uint256 amount) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function rescueToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}