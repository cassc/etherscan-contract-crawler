// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router02.sol";
import "./Ham.sol";
import "./interface/IHam.sol";
import "./interface/IOnRye.sol";
import "./ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Ciel is
    ERC20Permit,
    Ownable,
    ReentrancyGuard
{
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    IHam public ham;

    IOnRye public onRye;

    address public marketingWallet;

    address public developmentWallet;

    uint256 public constant DECIMALS = 10**18;

    uint256 public constant TOTAL_SUPPLY = 10**9 * DECIMALS; //1 billion

    mapping(address => bool) public rewardAddressWhitelisted;

    mapping(address => bool) public _canTransferBeforeOpenTrading;

    mapping(address => bool) public maxWalletExcluded;

    uint256 public maxWalletAmount;

    // Sell Fees
    uint256 private _sellLiquidityFee; // 9%
    uint256 private _sellMarketingFee; // 0%
    uint256 private _sellDevelopmentFee; // 0%
    uint256 private _sellRewardsToHolders; // 5%

    // Sell Total
    uint256 private sellTotalFee;

    //buy total
    uint256 private buyTotalFee;

    // Thresholds
    uint256 public thresholdPercent;
    uint256 public thresholdDivisor;

    // Admin Flags
    bool public tradingOpen;
    bool public antiBotMode;

    bool private inSwap;

    uint256 public launchedAt;
    uint256 private deadBlocks;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isSniper;

    // Events
    event OpenTrading(uint256 launchedAt, bool tradingOpen);
    event RewardsTokenChosen(address user, address rewardsToken);
    event SetAutomatedMarketMakerPair(address newPair);
    event ExcludeFromRewards(address acount);
    event UpdateClaimWait(uint256 newTime);
    event SetNewRouter(address newRouter);
    event ExcludeFromFees(address account, bool isExcluded);
    event ManageSnipers(address[] indexed accounts, bool state);
    event SetWallet(address newWallet);
    event SetSwapThreshold(
        uint256 indexed newpercent,
        uint256 indexed newDivisor
    );
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    event MaxWalletExcluded(address wallet, bool isExcluded);
    event MaxWalletAmount(uint256 amount);
    event CanTransferBeforeOpenTrading(address user, bool isAllowed);
    event OnRyeSet(address payable onRye);
    event HamSet(address ham);
    event ETHWithdrawn(address to, uint256 amount);
    event RewardTokenRemoved(address rewardTokenAddress);

    modifier swapping(){
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address payable _marketingWallet, address payable _developmentWallet) ERC20("Ciel", "CIEL") ERC20Permit("Ciel") {
        require(_marketingWallet != address(0), "Ciel: No null address");
        require(_developmentWallet != address(0), "Ciel: No null address");

        marketingWallet = payable(_marketingWallet);
        developmentWallet = payable(_developmentWallet);

        _sellLiquidityFee = 0; // 9%
        _sellMarketingFee = 0; // 2%
        _sellDevelopmentFee = 0; // 2%
        _sellRewardsToHolders = 0; //5%

        buyTotalFee = 0; //18%

        sellTotalFee = _sellLiquidityFee + _sellMarketingFee + _sellDevelopmentFee + _sellRewardsToHolders;

        thresholdPercent = 20;
        thresholdDivisor = 1000;

        antiBotMode = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(_uniswapV2Router.WETH(), address(this));

        uniswapV2Router = _uniswapV2Router;

        excludeFromFees(_msgSender(), true);
        excludeFromFees(address(this), true);

        _canTransferBeforeOpenTrading[address(this)] = true;
        _canTransferBeforeOpenTrading[_msgSender()] = true;

        maxWalletAmount = (TOTAL_SUPPLY * 15) / 10000; //.15% of TOTAL_SUPPLY

        maxWalletExcluded[uniswapV2Pair] = true;
        maxWalletExcluded[_msgSender()] = true;
        maxWalletExcluded[address(this)] = true;

        _mint(_msgSender(), TOTAL_SUPPLY);

        emit Transfer(address(0), _msgSender(), TOTAL_SUPPLY);
    }

    function setMaxWalletExcluded(address wallet, bool isExcluded)
        external
        onlyOwner
    {
        maxWalletExcluded[wallet] = isExcluded;
        emit MaxWalletExcluded(wallet, isExcluded);
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        require(amount > (TOTAL_SUPPLY * 15) / 10000000, "CIEL: too small");  //.00015% of TOTAL_SUPPLY
        maxWalletAmount = amount;
        emit MaxWalletAmount(amount);
    }

    function setCanTransferBeforeOpenTrading(address user, bool isAllowed)
        external
        onlyOwner
    {
        _canTransferBeforeOpenTrading[user] = isAllowed;
        emit CanTransferBeforeOpenTrading(user, isAllowed);
    }

    function setOnRye(address payable _onRye) external onlyOwner {
        require(_onRye != address(0), "No null address");
        onRye = IOnRye(payable(_onRye));
        emit OnRyeSet(_onRye);
    }

    function setHam(address _ham) external onlyOwner {
        require(_ham != address(0), "No null address");
        ham = IHam(_ham);
        emit HamSet(_ham);
    }

    function toggleAntiBot() external onlyOwner {
        if (antiBotMode) {
            antiBotMode = false;
        } else {
            antiBotMode = true;
        }
    }

    function initializeExclusion() external onlyOwner {
        ham.eFR(address(onRye));
        ham.eFR(uniswapV2Pair);
        ham.eFR(address(this));
        ham.eFR(_msgSender());
        ham.eFR(
            address(0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD)
        );
    }

    function initializeRewardTokens() external onlyOwner {
        addRewardAddress(address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599), true); // WBTC
        addRewardAddress(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), true); // WETH
        addRewardAddress(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), true); // USDC
        addRewardAddress(address(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE), true); // SHIBA
        addRewardAddress(address(0x45804880De22913dAFE09f4980848ECE6EcbAf78), true); // PAXG
        addRewardAddress(address(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942), true); // MANA
        addRewardAddress(address(0x514910771AF9Ca656af840dff83E8264EcF986CA), true); // LINK
        addRewardAddress(address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2), true); // MKR
        addRewardAddress(address(0x0D8775F648430679A709E98d2b0Cb6250d2887EF), true); // BAT
        addRewardAddress(address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984), true); // UNI
        addRewardAddress(address(this), false); // CIEL
    }


    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function claim() external {
        require(tradingOpen, "CIEL: Trading not open");
        bool processed = ham.pA(payable(_msgSender()), false);
        require(processed, "Unsuccessful claim");
    }

    function curentSwapThreshold() internal view returns (uint256) {
        return (balanceOf(uniswapV2Pair) * thresholdPercent) / thresholdDivisor;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "No null address");
        require(to != address(0), "No null address");
        require(amount > 0, "Amount cannot be zero");
        require(!_isSniper[to] && !_isSniper[from], "NS");
        if (!tradingOpen) {
            require(
                _canTransferBeforeOpenTrading[from] ||
                    _canTransferBeforeOpenTrading[to], 
                    "Cannot transfer"
            );
        }

        if (
            launchedAt > 0 &&
            (launchedAt + 1000) > block.number &&
            !maxWalletExcluded[to]
        ) {
            require(balanceOf(to) + amount <= maxWalletAmount, "CIEL: maxW");
        }

        uint256 currenttotalFee;

        if (to == uniswapV2Pair) {
            //sell
            currenttotalFee = sellTotalFee;
        }

        if(from == uniswapV2Pair) {
            //buy
            currenttotalFee = buyTotalFee;
        }

        //antibot - first X blocks
        if (launchedAt > 0 && (launchedAt + deadBlocks) > block.number) {
            _isSniper[to] = true;
        }

        //high slippage bot txns
        if (
            launchedAt > 0 &&
            from != owner() &&
            block.number <= (launchedAt + deadBlocks) &&
            antiBotMode
        ) {
            currenttotalFee = 950; //95%
        }

        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            from == owner()
        ) {
            //privileged
            currenttotalFee = 0;
        }
        //sell
        if (!inSwap && tradingOpen && to == uniswapV2Pair && currenttotalFee > 0) {
            //add liquidity before opening trading to this doesn't hit
            uint256 contractTokenBalance = balanceOf(address(this));
            uint256 swapThreshold = curentSwapThreshold();

            if ((contractTokenBalance >= swapThreshold)) {
                swapAndsendEth();
            }
        }
        _transferStandard(from, to, amount, currenttotalFee);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 curentTotalFee
    ) private nonReentrant {
        if (curentTotalFee == 0) {
            super._transfer(sender, recipient, tAmount);
        } else {
            uint256 calcualatedFee = (tAmount * curentTotalFee) / (10**3);
            uint256 amountForRecipient = tAmount - calcualatedFee;
            super._transfer(sender, address(this), calcualatedFee); //take tax
            super._transfer(sender, recipient, amountForRecipient);

            // Add to total pending dividends
            uint256 calculatedDividends = (tAmount * _sellRewardsToHolders) / (10**3);
            uint256 currentDividends = onRye
                .gTDD();
            onRye.sTPD(
                currentDividends + calculatedDividends
            );
        }
        //update tracker values
        try
            ham.sb(payable(sender), balanceOf(sender))
        {} catch {}
        try
            ham.sb(payable(recipient), balanceOf(recipient))
        {} catch {}
    }

    function swapAndsendEth() private swapping {
        uint256 amountToLiquify;
        if (_sellLiquidityFee > 0) {
            amountToLiquify = (curentSwapThreshold() * _sellLiquidityFee) / sellTotalFee / 2;
            swapTokensForEth(amountToLiquify);
        }

        uint256 amountETH = address(this).balance;

        if (sellTotalFee > 0) {
            uint256 totalETHFee = sellTotalFee - (_sellLiquidityFee / 2); 
            uint256 amountETHLiquidity = amountETH * _sellLiquidityFee / sellTotalFee / 2;

            if (amountETH > 0) {
                if(_sellDevelopmentFee > 0){
                    uint256 developmentAllocation = amountETH * _sellDevelopmentFee / totalETHFee;

                    (bool dSuccess, ) = payable(developmentWallet).call{
                        value: developmentAllocation
                    }("");
                    if (dSuccess) {
                        emit Transfer(
                            address(this),
                            developmentWallet,
                            developmentAllocation
                        );
                    }
                }
                
                if(_sellMarketingFee > 0){
                    uint256 marketingAllocation = amountETH * _sellMarketingFee / totalETHFee;

                    (bool mSuccess, ) = payable(marketingWallet).call{
                        value: marketingAllocation
                    }("");
                    if (mSuccess) {
                        emit Transfer(
                            address(this),
                            marketingWallet,
                            marketingAllocation
                        );
                    }
                }

                if(_sellRewardsToHolders > 0){
                    uint256 rewardETHAllocation = amountETH * _sellRewardsToHolders / totalETHFee;

                    (bool rSuccess, ) = payable(onRye).call{
                        value: rewardETHAllocation
                    }("");
                    if (rSuccess) {
                        emit Transfer(
                            address(this),
                            address(onRye),
                            rewardETHAllocation
                        );
                    }
                }
            }
            if (amountToLiquify > 0) {
                addLiquidity(amountToLiquify, amountETHLiquidity);
            }
        } else {
            if (amountETH > 0) {
                (bool mSuccess, ) = address(marketingWallet).call{
                    value: amountETH
                }("");
                if (mSuccess) {
                    emit Transfer(address(this), marketingWallet, amountETH);
                }
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        super._approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            1,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        super._approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    function processDividendTracker(uint256 gas) external onlyOwner nonReentrant {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = ham.p(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function setThreshold(uint256 newPercent, uint256 newDivisor)
        external
        onlyOwner
    {
        require(newDivisor > 0 && newPercent > 0, "CIEL: must be < 0");
        thresholdPercent = newPercent;
        thresholdDivisor = newDivisor;
        emit SetSwapThreshold(thresholdPercent, thresholdDivisor);
    }

    function setWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != address(0), "CIEL: no null addres");
        marketingWallet = newMarketingWallet;
        emit SetWallet(marketingWallet);
    }

    function openTrading(bool state, uint256 _deadBlocks) external onlyOwner {
        tradingOpen = state;
        if (tradingOpen && launchedAt == 0) {
            launchedAt = block.number;
            deadBlocks = _deadBlocks + 2;
        }
        emit OpenTrading(launchedAt, tradingOpen);
    }

    function setAutomatedMarketMakerPair(address newPair) external onlyOwner nonReentrant {
        require(newPair != address(0), "CIEL: no null address");
        require(newPair != uniswapV2Pair, "CIEL: Same Pair");
        ham.eFR(newPair);
        uniswapV2Pair = newPair;
        emit SetAutomatedMarketMakerPair(uniswapV2Pair);
    }

    function setNewRouter(address newRouter) external onlyOwner nonReentrant {
        require(newRouter != address(0), "No null address");
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address getPair = IUniswapV2Factory(_newRouter.factory()).getPair(
            address(this),
            _newRouter.WETH()
        );
        if (getPair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(
                address(this),
                _newRouter.WETH()
            );
        } else {
            uniswapV2Pair = getPair;
        }
        uniswapV2Router = _newRouter;
        emit SetNewRouter(newRouter);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        require(account != address(0), "No null address");
        _isExcludedFromFee[account] = isExcluded;
        emit ExcludeFromFees(account, isExcluded);
    }

    function manageSnipers(address[] memory accounts, bool state)
        external
        onlyOwner
    {
        for (uint256 i; i < accounts.length; ++i) {
            _isSniper[accounts[i]] = state;
        }
        emit ManageSnipers(accounts, state);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner nonReentrant {
        require(claimWait <= 604800, "CIEL: shorter");
        ham.uCW(claimWait);
        emit UpdateClaimWait(claimWait);
    }

    function withdrawStuckTokens(IERC20 token, address to) external onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(to, balance);
        require(success, "Failed");
        emit Transfer(address(this), to, balance);
    }

    function withdrawETHFromContract(address to) external onlyOwner nonReentrant {
        require(to != address(0), "CIEL: No null address");
        require(address(this).balance != 0, "CIEL: no ETH");
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{value: balance}("");
        require(success, "Failed");
        emit ETHWithdrawn(to, balance);
    }

    function setUserRewardToken(address holder, address rewardTokenAddress)
        external
        nonReentrant
    {
        require(
            rewardTokenAddress.isContract() && rewardTokenAddress != address(0),
            "CIEL: Address is invalid."
        );
        require(
            holder == payable(_msgSender()),
            "CIEL: can only set for yourself."
        );
        require(
            rewardAddressWhitelisted[rewardTokenAddress] == true,
            "CIEL: not in list"
        );
        onRye.sUCRT(holder, rewardTokenAddress);
        emit RewardsTokenChosen(holder, rewardTokenAddress);
    }

    function addRewardAddress(address rewardTokenAddress, bool shouldSwap)
        public
        onlyOwner
    {
        require(
            rewardTokenAddress.isContract() && rewardTokenAddress != address(0),
            "CIEL: Address is invalid."
        );
        require(rewardAddressWhitelisted[rewardTokenAddress] != true, "CIEL: already in list");
        rewardAddressWhitelisted[rewardTokenAddress] = true;
        onRye.sTA(rewardTokenAddress, true);
        onRye.sTSS(rewardTokenAddress, shouldSwap);
    }

    function removeRewardAddress(address rewardTokenAddress)
        external
        onlyOwner
        nonReentrant
    {
        require(
            rewardAddressWhitelisted[rewardTokenAddress] == true,
            "CIEL: Token not found"
        );
        delete rewardAddressWhitelisted[rewardTokenAddress];
        onRye.dTA(rewardTokenAddress);
        onRye.dTSS(rewardTokenAddress);
        emit RewardTokenRemoved(rewardTokenAddress);
    }

    function excludeFromRewards(address account) external onlyOwner nonReentrant {
        require(account != address(0), "No null address");
        ham.eFR(account);
        emit ExcludeFromRewards(account);
    }

    receive() external payable {}
}