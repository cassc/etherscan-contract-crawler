// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "./DividendTokenDividendTracker.sol";
interface IUniswapV2Caller {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external;
}
interface IFee {
    function payFee(
        uint256 _tokenType
    ) external payable;
}
contract DividendToken is ERC20, Ownable {
    IUniswapV2Caller public constant uniswapV2Caller =
        IUniswapV2Caller(0x1CcFE8c40eF259566433716002E379dFfFbf5a3e);
    IFee public constant feeContract = IFee(0xfd6439AEfF9d2389856B7486b9e74a6DacaDcDCe);

    address public tokenForMarketingFee;
    uint8 private _decimals;
    address public baseTokenForPair;
    address public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    address public dividendTracker;

    address public rewardToken;

    uint256 public swapTokensAtAmount;

    uint16 public sellRewardFee;
    uint16 public buyRewardFee;

    uint16 public sellLiquidityFee;
    uint16 public buyLiquidityFee;

    uint16 public sellMarketingFee;
    uint16 public buyMarketingFee;

    address public _marketingWalletAddress;
    uint256 public gasForProcessing;
    uint256 public maxWallet;
    uint256 public maxTransactionAmount;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public isExcludedFromMaxTransactionAmount;
    uint256 private _liquidityFeeTokens;
    uint256 private _marketingFeeTokens;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdateSwapTokensAtAmount(uint256 newSwapTokensAtAmount, uint256 oldSwapTokensAtAmount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event UpdateMaxWallet(uint256 newMaxWallet, uint256 oldMaxWallet);
    event UpdateMaxTransactionAmount(uint256 newMaxTransactionAmount, uint256 oldMaxTransactionAmount);
    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );
    event MarketingWalletUpdated(
        address indexed newMarketingWallet,
        address indexed oldMarketingWallet
    );
    event TokenForMarketingFeeUpdated(
        address indexed newTokenForMarketingFee,
        address indexed oldTokenForMarketingFee);
    event ExcludedFromMaxTransactionAmount(address indexed account, bool isExcluded);


    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event UpdateLiquidityFee(
        uint16 newSellLiquidityFee,
        uint16 newBuyLiquidityFee,
        uint16 oldSellLiquidityFee,
        uint16 oldBuyLiquidityFee
    );
    event UpdateMarketingFee(
        uint16 newSellMarketingFee,
        uint16 newBuyMarketingFee,
        uint16 oldSellMarketingFee,
        uint16 oldBuyMarketingFee
    );
    event UpdateRewardFee(
        uint16 newSellRewardFee,
        uint16 newBuyRewardFee,
        uint16 oldSellRewardFee,
        uint16 oldBuyRewardFee
    );  

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee
    ) payable ERC20(name_, symbol_) {
        feeContract.payFee{value: msg.value}(3);        
        _decimals = decimals_;
        rewardToken = addrs[0];
        _marketingWalletAddress = addrs[2];
        emit MarketingWalletUpdated(_marketingWalletAddress, address(0));
        baseTokenForPair=addrs[4];
        sellLiquidityFee = feeSettings[0];
        buyLiquidityFee = feeSettings[1];
        emit UpdateLiquidityFee(
            sellLiquidityFee,
            buyLiquidityFee,
            0,
            0
        );
        sellMarketingFee = feeSettings[2];
        buyMarketingFee = feeSettings[3];
        emit UpdateMarketingFee(
            sellMarketingFee,
            buyMarketingFee,
            0,
            0
        );
        sellRewardFee = feeSettings[4];
        buyRewardFee = feeSettings[5];
        emit UpdateRewardFee(
            sellRewardFee,
            buyRewardFee,
            0,
            0
        );  
        require(sellLiquidityFee+sellMarketingFee+sellRewardFee <= 200, "sell fee < 20%");
        require(buyLiquidityFee+buyMarketingFee+buyRewardFee <= 200, "buy fee < 20%");
        if(_tokenForMarketingFee==0){
            tokenForMarketingFee=address(this);
        }else if(_tokenForMarketingFee==1){
            tokenForMarketingFee=baseTokenForPair;
        }else{
            tokenForMarketingFee=rewardToken;
        }
        emit TokenForMarketingFeeUpdated(tokenForMarketingFee, address(0));
        swapTokensAtAmount = totalSupply_/(10000);
        emit UpdateSwapTokensAtAmount(swapTokensAtAmount, 0);
        gasForProcessing = 300000;
        emit GasForProcessingUpdated(gasForProcessing, 0);

        dividendTracker = payable(Clones.clone(addrs[3]));
        emit UpdateDividendTracker(
            dividendTracker,
            address(0)
        );
        DividendTokenDividendTracker(dividendTracker).initialize(
            rewardToken,
            minimumTokenBalanceForDividends_
        );
        require(_maxTransactionAmount>0, "max transaction amount > 0");
        require(_maxWallet>0, "max wallet >0");
        maxWallet=_maxWallet;
        emit UpdateMaxWallet(maxWallet, 0);
        maxTransactionAmount=_maxTransactionAmount;
        emit UpdateMaxTransactionAmount(maxTransactionAmount, 0);
        uniswapV2Router = addrs[1];
        emit UpdateUniswapV2Router(
            uniswapV2Router,
            address(0)
        );
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(uniswapV2Router).factory())
            .createPair(address(this), baseTokenForPair);
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        DividendTokenDividendTracker(dividendTracker).excludeFromDividends(dividendTracker);
        DividendTokenDividendTracker(dividendTracker).excludeFromDividends(address(this));
        DividendTokenDividendTracker(dividendTracker).excludeFromDividends(owner());
        DividendTokenDividendTracker(dividendTracker).excludeFromDividends(address(0xdead));
        DividendTokenDividendTracker(dividendTracker).excludeFromDividends(uniswapV2Router);

        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true); 
        isExcludedFromMaxTransactionAmount[address(0xdead)]=true;
        isExcludedFromMaxTransactionAmount[address(this)]=true;
        isExcludedFromMaxTransactionAmount[_marketingWalletAddress]=true;
        isExcludedFromMaxTransactionAmount[owner()]=true;     
        _mint(owner(), totalSupply_);
    }

    receive() external payable {}

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "swapTokensAtAmount > 0");
        emit UpdateSwapTokensAtAmount(amount, swapTokensAtAmount);
        swapTokensAtAmount = amount;        
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != dividendTracker,
            "The dividend tracker already has that address"
        );

        address newDividendTracker =payable(newAddress);

        require(
            DividendTokenDividendTracker(newDividendTracker).owner() == address(this),
            "The new dividend tracker must be owned by the DIVIDENEDTOKEN token contract"
        );

        DividendTokenDividendTracker(newDividendTracker).excludeFromDividends(newDividendTracker);
        DividendTokenDividendTracker(newDividendTracker).excludeFromDividends(address(this));
        DividendTokenDividendTracker(newDividendTracker).excludeFromDividends(owner());
        DividendTokenDividendTracker(newDividendTracker).excludeFromDividends(uniswapV2Router);
        DividendTokenDividendTracker(newDividendTracker).excludeFromDividends(uniswapV2Pair);

        emit UpdateDividendTracker(newAddress, dividendTracker);

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Pair(address _baseTokenForPair) external onlyOwner
    {
        baseTokenForPair=_baseTokenForPair;
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(uniswapV2Router).factory()).createPair(
            address(this),
            baseTokenForPair
        );
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    }
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != uniswapV2Router,
            "The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, uniswapV2Router);
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(newAddress).factory())
            .createPair(address(this), baseTokenForPair);
        uniswapV2Router = newAddress;
        if (!DividendTokenDividendTracker(dividendTracker).isExcludedFromDividends(uniswapV2Router))
            DividendTokenDividendTracker(dividendTracker).excludeFromDividends(uniswapV2Router);
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet>0, "maxWallet>0");
        emit UpdateMaxWallet(_maxWallet, maxWallet);
        maxWallet = _maxWallet;        
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        require(_maxTransactionAmount>0, "maxTransactionAmount>0");
        emit UpdateMaxTransactionAmount(_maxTransactionAmount, maxTransactionAmount);
        maxTransactionAmount = _maxTransactionAmount;        
    }   

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "already");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        require(_marketingWalletAddress!=wallet, "already");
        emit MarketingWalletUpdated(_marketingWalletAddress, wallet);
        _marketingWalletAddress = wallet;        
    }

    function updateTokenForMarketingFee(address _tokenForMarketingFee) external onlyOwner {
        require(tokenForMarketingFee!=_tokenForMarketingFee, "already");
        emit TokenForMarketingFeeUpdated(_tokenForMarketingFee, tokenForMarketingFee);
        tokenForMarketingFee = _tokenForMarketingFee; 
    }

    function updateLiquidityFee(
        uint16 _sellLiquidityFee,
        uint16 _buyLiquidityFee
    ) external onlyOwner {
        require(
            _sellLiquidityFee+sellMarketingFee+sellRewardFee <= 200,
            "sell fee <= 20%"
        );
        require(
            _buyLiquidityFee+buyMarketingFee+buyRewardFee <= 200,
            "buy fee <= 20%"
        );
        emit UpdateLiquidityFee(
            _sellLiquidityFee,
            _buyLiquidityFee,
            sellLiquidityFee,
            buyLiquidityFee
        );
        sellLiquidityFee = _sellLiquidityFee;
        buyLiquidityFee = _buyLiquidityFee;   
    }

    function updateMarketingFee(
        uint16 _sellMarketingFee,
        uint16 _buyMarketingFee
    ) external onlyOwner {
        require(
            _sellMarketingFee+sellLiquidityFee+sellRewardFee <= 200,
            "sell fee <= 20%"
        );
        require(
            _buyMarketingFee+buyLiquidityFee+buyRewardFee <= 200,
            "buy fee <= 20%"
        );       
        emit UpdateMarketingFee(
            _sellMarketingFee,
            _buyMarketingFee,
            sellMarketingFee,
            buyMarketingFee
        );  
        sellMarketingFee = _sellMarketingFee;
        buyMarketingFee = _buyMarketingFee;        
    }

    function updateRewardFee(
        uint16 _sellRewardFee,
        uint16 _buyRewardFee
    ) external onlyOwner {
        require(
            _sellRewardFee+(sellLiquidityFee)+(sellMarketingFee) <= 200,
            "sell fee <= 20%"
        );
        require(
            _buyRewardFee+(buyLiquidityFee)+(buyMarketingFee) <= 200,
            "buy fee <= 20%"
        );
        emit UpdateRewardFee(
            _sellRewardFee, 
            _buyRewardFee,
            sellRewardFee, 
            buyRewardFee);
        sellRewardFee = _sellRewardFee;
        buyRewardFee = _buyRewardFee;        
    }


    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The main pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        isExcludedFromMaxTransactionAmount[pair] = value;
        if (value && !DividendTokenDividendTracker(dividendTracker).isExcludedFromDividends(pair)) {
            DividendTokenDividendTracker(dividendTracker).excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromMaxTransactionAmount(address account, bool isEx)
        external
        onlyOwner
    {
        require(isExcludedFromMaxTransactionAmount[account]!=isEx, "already");
        isExcludedFromMaxTransactionAmount[account] = isEx;
        emit ExcludedFromMaxTransactionAmount(account, isEx);
    }
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        DividendTokenDividendTracker(dividendTracker).updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return DividendTokenDividendTracker(dividendTracker).claimWait();
    }

    function updateMinimumTokenBalanceForDividends(uint256 amount)
        external
        onlyOwner
    {
        DividendTokenDividendTracker(dividendTracker).updateMinimumTokenBalanceForDividends(amount);
    }

    function getMinimumTokenBalanceForDividends()
        external
        view
        returns (uint256)
    {
        return DividendTokenDividendTracker(dividendTracker).minimumTokenBalanceForDividends();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return DividendTokenDividendTracker(dividendTracker).totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return DividendTokenDividendTracker(dividendTracker).withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return DividendTokenDividendTracker(dividendTracker).balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner {
        DividendTokenDividendTracker(dividendTracker).excludeFromDividends(account);
    }

    function isExcludedFromDividends(address account)
        public
        view
        returns (bool)
    {
        return DividendTokenDividendTracker(dividendTracker).isExcludedFromDividends(account);
    }

    function getAccountDividendsInfo(address account)
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
        return DividendTokenDividendTracker(dividendTracker).getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
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
        return DividendTokenDividendTracker(dividendTracker).getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = DividendTokenDividendTracker(dividendTracker).process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            msg.sender
        );
    }

    function claim() external {
        DividendTokenDividendTracker(dividendTracker).processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return DividendTokenDividendTracker(dividendTracker).getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return DividendTokenDividendTracker(dividendTracker).getNumberOfTokenHolders();
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

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            if(_marketingFeeTokens>0)
                swapAndSendToFee(_marketingFeeTokens);
            if(_liquidityFeeTokens>0)
                swapAndLiquify(_liquidityFeeTokens);

            uint256 sellTokens = balanceOf(address(this));
            if(sellTokens>0)
                swapAndSendDividends(sellTokens);
            _marketingFeeTokens=0;
            _liquidityFeeTokens=0;
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        uint256 _liquidityFee;
        uint256 _marketingFee;
        uint256 _rewardFee;
        if (takeFee) {
            if (automatedMarketMakerPairs[from]) {
                _rewardFee = amount*(buyRewardFee)/(1000);
                _liquidityFee = amount*(buyLiquidityFee)/(1000);
                _marketingFee = amount*(buyMarketingFee)/(1000);
            }
            else if (automatedMarketMakerPairs[to]) {
                _rewardFee = amount*(sellRewardFee)/(1000);
                _liquidityFee = amount*(sellLiquidityFee)/(1000);
                _marketingFee = amount*(sellMarketingFee)/(1000);
            }
            _liquidityFeeTokens = _liquidityFeeTokens+_liquidityFee;
            _marketingFeeTokens = _marketingFeeTokens+_marketingFee;
            uint256 _feeTotal=_rewardFee+_liquidityFee+_marketingFee;
            amount=amount-(_feeTotal);
            if(_feeTotal>0)
                super._transfer(from, address(this), _feeTotal);
        }
        
        super._transfer(from, to, amount);

        try
            DividendTokenDividendTracker(dividendTracker).setBalance(payable(from), balanceOf(from))
        {} catch {}
        try DividendTokenDividendTracker(dividendTracker).setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            if (!isExcludedFromMaxTransactionAmount[from]) {
                require(
                    amount < maxTransactionAmount,
                    "ERC20: exceeds transfer limit"
                );
            }
            if (!isExcludedFromMaxTransactionAmount[to]) {
                require(
                    balanceOf(to) < maxWallet,
                    "ERC20: exceeds max wallet limit"
                );
            }
            uint256 gas = gasForProcessing;

            try DividendTokenDividendTracker(dividendTracker).process(gas) returns (
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
                    msg.sender
                );
            } catch {}
        }
    }

    function swapAndSendToFee(uint256 tokens) private {
        if(tokenForMarketingFee==rewardToken){
            uint256 initialCAKEBalance = IERC20(rewardToken).balanceOf(
                address(this)
            );
            swapTokensForCake(tokens);
            uint256 newBalance = (IERC20(rewardToken).balanceOf(address(this)))-(
                initialCAKEBalance
            );
            IERC20(rewardToken).transfer(_marketingWalletAddress, newBalance);
        }else if(tokenForMarketingFee==baseTokenForPair){
            uint256 initialBalance = baseTokenForPair==IUniswapV2Router02(uniswapV2Router).WETH() ? address(this).balance 
                : IERC20(baseTokenForPair).balanceOf(address(this));
            swapTokensForBaseToken(tokens);
            uint256 newBalance = baseTokenForPair==IUniswapV2Router02(uniswapV2Router).WETH() ? address(this).balance-initialBalance
                : IERC20(baseTokenForPair).balanceOf(address(this))-initialBalance;
            if(baseTokenForPair==IUniswapV2Router02(uniswapV2Router).WETH()){
                (bool success, )=address(_marketingWalletAddress).call{value: newBalance}("");              
            }else{
                IERC20(baseTokenForPair).transfer(_marketingWalletAddress, newBalance);
            } 
        }else{
            _transfer(address(this), _marketingWalletAddress, tokens);
        }
        
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens/(2);
        uint256 otherHalf = tokens-(half);

        uint256 initialBalance = baseTokenForPair==IUniswapV2Router02(uniswapV2Router).WETH() ? address(this).balance 
            : IERC20(baseTokenForPair).balanceOf(address(this));

        swapTokensForBaseToken(half); 
        uint256 newBalance = baseTokenForPair==IUniswapV2Router02(uniswapV2Router).WETH() ? address(this).balance-initialBalance
            : IERC20(baseTokenForPair).balanceOf(address(this))-initialBalance;

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBaseToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = baseTokenForPair;

        if (path[1] == IUniswapV2Router02(uniswapV2Router).WETH()){
            _approve(address(this), uniswapV2Router, tokenAmount);
            IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of BaseToken
                path,
                address(this),
                block.timestamp
            );
        }else{
            _approve(address(this), address(uniswapV2Caller), tokenAmount);
            uniswapV2Caller.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    uniswapV2Router,
                    tokenAmount,
                    0, // accept any amount of BaseToken
                    path,
                    block.timestamp
                );
        }
    }

    function swapTokensForCake(uint256 tokenAmount) private {
        if(baseTokenForPair!=rewardToken){
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = baseTokenForPair;
            path[2] = rewardToken;

            _approve(address(this), uniswapV2Router, tokenAmount);

            IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }else{
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = rewardToken;

            _approve(address(this), address(uniswapV2Caller), tokenAmount);
            uniswapV2Caller.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                uniswapV2Router,
                tokenAmount,
                0, // accept any amount of BaseToken
                path,
                block.timestamp
            );            
        }
        
    }

    function addLiquidity(uint256 tokenAmount, uint256 baseTokenAmount) private {
        _approve(address(this), uniswapV2Router, tokenAmount);
        if (baseTokenForPair == IUniswapV2Router02(uniswapV2Router).WETH()) 
            IUniswapV2Router02(uniswapV2Router).addLiquidityETH{value: baseTokenAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(0xdead),
                block.timestamp
            );
        else{
            IERC20(baseTokenForPair).approve(uniswapV2Router, baseTokenAmount);
            IUniswapV2Router02(uniswapV2Router).addLiquidity(
                address(this),
                baseTokenForPair,
                tokenAmount,
                baseTokenAmount,
                0,
                0,
                address(0xdead),
                block.timestamp
            );    
        }
                
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForCake(tokens);
        uint256 dividends = IERC20(rewardToken).balanceOf(address(this));
        bool success = IERC20(rewardToken).transfer(
            dividendTracker,
            dividends
        );

        if (success) {
            DividendTokenDividendTracker(dividendTracker).distributeCAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}