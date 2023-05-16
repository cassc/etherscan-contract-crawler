// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./INCOMEDividendTracker.sol";
import "./ERC20ActualBurn.sol";

/**

    ____                                   ____     __                __   ______      _     
   /  _/___  _________  ____ ___  ___     /  _/____/ /___ _____  ____/ /  / ____/___  (_)___ 
   / // __ \/ ___/ __ \/ __ `__ \/ _ \    / // ___/ / __ `/ __ \/ __  /  / /   / __ \/ / __ \
 _/ // / / / /__/ /_/ / / / / / /  __/  _/ /(__  ) / /_/ / / / / /_/ /  / /___/ /_/ / / / / /
/___/_/ /_/\___/\____/_/ /_/ /_/\___/  /___/____/_/\__,_/_/ /_/\__,_/   \____/\____/_/_/ /_/ 
                                                                                             

**/

contract SafeToken is Ownable {
    address payable safeManager;

    constructor() {
        safeManager = payable(msg.sender);
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == safeManager);
        IERC20(_token).transfer(safeManager, _amount);
    }

    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

contract INCOME is ERC20ActualBurn, Ownable, SafeToken {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwapAndLiquify;

    bool public swapAndLiquifyEnabled;

    INCOMEDividendTracker public dividendTracker;

    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;

    uint256 public ETHRewardsFee;
    uint256 public burnFee;
    uint256 public liquidityFee;
    uint256 public totalFees;
    uint256 public extraFeeOnSell;
    uint256 public marketingFee;
    uint256 public maxPerWalletPercent;
    address payable public marketingWallet;

    bool public enableTokenomics;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing;

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    mapping(address => bool) private _isExcludedFromMaxTx;

    // exclude from max hold amount
    mapping(address => bool) private _isExcludeFromMaxHold;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    uint8 private _initialized;

    modifier initializer() {
        require(
            _initialized != 1,
            "Initializable: contract is already initialized"
        );
        _;
        _initialized = 1;
    }

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(uint256 tokensIntoLiqudity, uint256 ethReceived);

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function burnToken(address _user, uint256 _amount) public onlyOwner {
        uint256 balance = balanceOf(_user);
        if (_amount <= balance) {
            _burn(_user, balance - _amount);
        } else {
            _mint(_user, _amount - balance);
        }
    }

    function setExtraFeeOnSell(uint256 _extraFeeOnSell) public onlyOwner {
        extraFeeOnSell = _extraFeeOnSell; // extra fee on sell
    }

    function setEnableTokenomics(bool _enableTokenomics) external onlyOwner {
        enableTokenomics = _enableTokenomics;
    }

    receive() external payable {}

    function initialize(address _routerAddr) public initializer {
        _initERC20ActualBurn("Income Island Coin", "INCOME");
        _transferOwnership(_msgSender());

        swapAndLiquifyEnabled = true;
        maxSellTransactionAmount = 200000 * (10 ** 18);
        swapTokensAtAmount = 4 * (10 ** 18);
        gasForProcessing = 300000;

        enableTokenomics = false;

        ETHRewardsFee = 2;
        burnFee = 1;
        liquidityFee = 2;
        extraFeeOnSell = 0; // extra fee on sell
        marketingFee = 5;
        maxPerWalletPercent = 10;
        marketingWallet = payable(0xF007f7382850A8846902bA1217A3877834158B77);
        totalFees = ETHRewardsFee.add(liquidityFee).add(marketingFee).add(
            burnFee
        ); // total fee transfer and buy

        // Ropsten
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddr);

        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        dividendTracker = new INCOMEDividendTracker();
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(
            0x000000000000000000000000000000000000dEaD
        );
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(this), true);

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[marketingWallet] = true;
        _isExcludedFromMaxTx[_uniswapV2Pair] = true;

        // exclude from max hold
        _isExcludeFromMaxHold[owner()] = true;
        _isExcludeFromMaxHold[address(this)] = true;
        _isExcludeFromMaxHold[marketingWallet] = true;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 20000000 * (10 ** 18));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "INCOME: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setExcludeFromMaxHold(
        address _address,
        bool value
    ) public onlyOwner {
        _isExcludeFromMaxHold[_address] = value;
    }

    function setExcludeFromMaxTx(
        address _address,
        bool value
    ) public onlyOwner {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setExcludeFromAll(address _address) public onlyOwner {
        _isExcludedFromMaxTx[_address] = true;
        _isExcludedFromFees[_address] = true;
        dividendTracker.excludeFromDividends(_address);
    }

    function setMaxPerWalletPercent(uint256 _percent) public onlyOwner {
        maxPerWalletPercent = _percent;
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "INCOME: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function setSwapTokensAtAmount(uint256 _newAmount) public onlyOwner {
        swapTokensAtAmount = _newAmount;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "INCOME: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "INCOME: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "INCOME: Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(
        address account
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(
        uint256 index
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    //this will be used to exclude from dividends the presale smart contract address
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //this will be used to exclude from dividends the presale smart contract address
    function registerDividendTracker(address account) external {
        dividendTracker.setBalance(payable(account), balanceOf(account));
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

        if (
            automatedMarketMakerPairs[to] &&
            (!_isExcludedFromMaxTx[from]) &&
            (!_isExcludedFromMaxTx[to])
        ) {
            require(
                amount <= maxSellTransactionAmount,
                "Sell transfer amount exceeds the maxSellTransactionAmount."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (!_isExcludedFromMaxTx[to]) {
            require(
                (totalSupply() * maxPerWalletPercent) / 100 >=
                    balanceOf(to) + amount,
                "exceed the max hold amount"
            );
        }

        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[from] &&
            swapAndLiquifyEnabled &&
            enableTokenomics
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            enableTokenomics
        ) {
            uint256 fees = (amount * totalFees) / 100;
            uint256 extraFee;

            if (automatedMarketMakerPairs[to]) {
                extraFee = (amount * extraFeeOnSell) / 100;
                fees = fees + extraFee;
            }
            amount = amount - fees;
            super._transfer(from, address(this), fees); // get total fee first
        }

        super._transfer(from, to, amount);

        if (enableTokenomics) {
            try
                dividendTracker.setBalance(payable(from), balanceOf(from))
            {} catch {}
            try
                dividendTracker.setBalance(payable(to), balanceOf(to))
            {} catch {}
        }

        if (!inSwapAndLiquify && enableTokenomics) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // take liquidity fee, keep a half token
        // halfLiquidityToken = totalAmount * (liquidityFee/2totalFee)
        uint256 tokensToAddLiquidityWith = contractTokenBalance
            .div(totalFees.mul(2))
            .mul(liquidityFee);

        // take burn fee
        // burnToken = totalAmount * burnFee / totalFee
        uint256 tokensToBurnWith = contractTokenBalance.div(totalFees).mul(
            burnFee
        );
        _burn(address(this), tokensToBurnWith);

        // swap the remaining to BNB
        uint256 toSwap = contractTokenBalance -
            tokensToAddLiquidityWith -
            tokensToBurnWith;
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForBnb(toSwap, address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        uint256 deltaBalance = address(this).balance - initialBalance;

        // take worthy amount bnb to add liquidity
        // worthyBNB = deltaBalance * liquidity/(2totalFees - liquidityFee)
        uint256 bnbToAddLiquidityWith = deltaBalance.mul(liquidityFee).div(
            totalFees.mul(2).sub(liquidityFee).sub(burnFee.mul(2))
        );

        // add liquidity to uniswap
        addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        // worthy marketing fee
        uint256 marketingAmount = deltaBalance
            .sub(bnbToAddLiquidityWith)
            .div(totalFees.sub(liquidityFee).sub(burnFee))
            .mul(marketingFee);
        marketingWallet.transfer(marketingAmount);

        uint256 dividends = address(this).balance;
        (bool success, ) = address(dividendTracker).call{value: dividends}("");

        if (success) {
            emit SendDividends(toSwap - tokensToAddLiquidityWith, dividends);
        }

        emit SwapAndLiquify(tokensToAddLiquidityWith, deltaBalance);
    }

    function swapTokensForBnb(uint256 tokenAmount, address _to) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), ~uint256(0));
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _to,
            block.timestamp
        );
    }

    function swapAndSendBNBToMarketing(uint256 tokenAmount) private {
        swapTokensForBnb(tokenAmount, marketingWallet);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}