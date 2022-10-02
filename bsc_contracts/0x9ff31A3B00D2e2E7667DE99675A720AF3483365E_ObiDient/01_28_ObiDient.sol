// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../IUniswapV2Router02.sol";
import "./ObiDientTokenDividendTracker.sol";
import "../BaseToken.sol";
import "../IUniswapV2Factory.sol";

contract ObiDient is ERC20, Ownable, BaseToken {
    using SafeMath for uint256;

    uint256 public constant VERSION = 1;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    ObiDientTokenDividendTracker public dividendTracker;

    address public rewardToken;
    uint256 constant FEE_DENOMINATOR = 10000;

    uint256 private constant BNB_DECIMALS = 18;
    uint256 private constant BUSD_DECIMALS = 18;

    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // mainnet
    // address constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // testnet

    address public publicCampaignWallet =
        0x173628795ad1954a11f5870dD2882A0C8dE485A2;
    address public developmentWallet =
        0x94dFac87E2F2ED3EdF439c61027D10AD4A9EBFC9;
    bool public internalTradingEnabled = false;

    uint256 public swapTokensAtAmount;

    uint256 public spreadDivisor = 9400;

    uint256 public bLiquidityFee = 500;
    uint256 public bPublicCampaignFee = 500;
    uint256 public bTokenRewardsFee = 200;
    uint256 public bReferralFee = 200;
    uint256 public bDevelopmentFee = 100;
    uint256 public bTotalFees = 1500;

    uint256 public sLiquidityFee = 500;
    uint256 public sPublicCampaignFee = 700;
    uint256 public sTokenRewardsFee = 300;
    uint256 public sReferralFee = 200;
    uint256 public sDevelopmentFee = 100;
    uint256 public sTotalFees = 1800;

    uint256 public gasForProcessing;

    bool public autoSwapEnabled = true;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    mapping(address => address) public refs;
    mapping(address => uint256) public refRewards;
    mapping(address => uint256) public refCount;
    mapping(address => address[]) public refList;
    mapping(address => mapping(address => uint256)) public refRewardsPerRef;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
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
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event TresuryReceived(address indexed receiver, uint256 indexed amount);

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
        swapping = true;
        _;
        swapping = false;
    }

    constructor(
        uint256 totalSupply_,
        address[3] memory addrs, // reward, router, dividendTracker
        uint256 minimumTokenBalanceForDividends_
    ) ERC20("ObiDient Token", "OBID") {
        rewardToken = addrs[0];
        swapTokensAtAmount = 100 ether; // Swap at 100 OBID
        // use by default 300,000 gas to process auto-claiming dividends
        gasForProcessing = 300000;

        dividendTracker = ObiDientTokenDividendTracker(
            payable(Clones.clone(addrs[2]))
        );
        dividendTracker.initialize(
            rewardToken,
            minimumTokenBalanceForDividends_
        );

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(addrs[1]);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(publicCampaignWallet);
        dividendTracker.excludeFromDividends(developmentWallet);
        dividendTracker.excludeFromDividends(address(0xdead));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        // exclude from paying fees or having max transaction amount

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(publicCampaignWallet), true);
        excludeFromFees(address(developmentWallet), true);
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply_);
        // Transfer ownership
        // _transferOwnership(developmentWallet);

        emit TokenCreated(
            developmentWallet,
            address(this),
            TokenType.baby,
            VERSION
        );
    }

    function setAutoSwapEnabled(bool _enabled) external onlyOwner {
        autoSwapEnabled = _enabled;
    }

    function setBuyFees(
        uint256 _bLiquidityFee,
        uint256 _bPublicCampaignFee,
        uint256 _bTokenRewardsFee,
        uint256 _bReferralFee,
        uint256 _bDevelopmentFee
    ) external onlyOwner {
        require(
            _bLiquidityFee +
                _bPublicCampaignFee +
                _bTokenRewardsFee +
                _bReferralFee +
                _bDevelopmentFee <=
                2500,
            "Fee can not over 25%"
        );
        bLiquidityFee = _bLiquidityFee;
        bPublicCampaignFee = _bPublicCampaignFee;
        bTokenRewardsFee = _bTokenRewardsFee;
        bReferralFee = _bReferralFee;
        bDevelopmentFee = _bDevelopmentFee;
    }

    function setSellFees(
        uint256 _sLiquidityFee,
        uint256 _sPublicCampaignFee,
        uint256 _sTokenRewardsFee,
        uint256 _sReferralFee,
        uint256 _sDevelopmentFee
    ) external onlyOwner {
        require(
            _sLiquidityFee +
                _sPublicCampaignFee +
                _sTokenRewardsFee +
                _sReferralFee +
                _sDevelopmentFee <=
                2500,
            "Fee can not over 25%"
        );
        sLiquidityFee = _sLiquidityFee;
        sPublicCampaignFee = _sPublicCampaignFee;
        sTokenRewardsFee = _sTokenRewardsFee;
        sReferralFee = _sReferralFee;
        sDevelopmentFee = _sDevelopmentFee;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }

    function setPublicCampaignWallet(address _publicCampaignWallet)
        external
        onlyOwner
    {
        publicCampaignWallet = _publicCampaignWallet;
    }

    function setDevelopmentWallet(address _developmentWallet)
        external
        onlyOwner
    {
        developmentWallet = _developmentWallet;
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "OBID: The dividend tracker already has that address"
        );

        ObiDientTokenDividendTracker newDividendTracker = ObiDientTokenDividendTracker(
                payable(newAddress)
            );

        require(
            newDividendTracker.owner() == address(this),
            "OBID: The new dividend tracker must be owned by the OBID token contract"
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "OBID: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "OBID: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
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

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "OBID: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "OBID: Automated market maker pair is already set to that value"
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
            "OBID: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "OBID: Cannot update gasForProcessing to same value"
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

    function updateMinimumTokenBalanceForDividends(uint256 amount)
        external
        onlyOwner
    {
        dividendTracker.updateMinimumTokenBalanceForDividends(amount);
    }

    function getMinimumTokenBalanceForDividends()
        external
        view
        returns (uint256)
    {
        return dividendTracker.minimumTokenBalanceForDividends();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function isExcludedFromDividends(address account)
        public
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromDividends(account);
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
        return dividendTracker.getAccount(account);
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
            to != owner() &&
            autoSwapEnabled
        ) {
            swapping = true;
            uint256 totalFeesExceptRef = sTotalFees.sub(sReferralFee);
            uint256 swapTokens = contractTokenBalance.mul(sLiquidityFee).div(
                totalFeesExceptRef
            );
            swapAndLiquify(swapTokens);

            uint256 publicCampaignTokens = contractTokenBalance
                .mul(sPublicCampaignFee)
                .div(totalFeesExceptRef);
            uint256 developmentTokens = contractTokenBalance
                .mul(sDevelopmentFee)
                .div(totalFeesExceptRef);
            super._transfer(
                address(this),
                publicCampaignWallet,
                publicCampaignTokens
            );
            super._transfer(
                address(this),
                developmentWallet,
                developmentTokens
            );

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (
            takeFee &&
            (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to])
        ) {
            uint256 totalFeesTokens = amount.mul(bTotalFees).div(
                FEE_DENOMINATOR
            );
            uint256 refTokens = amount.mul(bReferralFee).div(FEE_DENOMINATOR);
            if (automatedMarketMakerPairs[to]) {
                totalFeesTokens = amount.mul(sTotalFees).div(FEE_DENOMINATOR);
                refTokens = amount.mul(sReferralFee).div(FEE_DENOMINATOR);
            }

            amount = amount.sub(totalFeesTokens);
            super._transfer(from, address(this), totalFeesTokens);

            if (automatedMarketMakerPairs[to]) {
                if (refs[from] == address(0)) {
                    super._transfer(address(this), from, refTokens);
                } else {
                    super._transfer(address(this), refs[from], refTokens);
                    refRewards[refs[from]] = refRewards[refs[from]].add(
                        refTokens
                    );
                    refRewardsPerRef[refs[from]][from] = refRewardsPerRef[
                        refs[from]
                    ][from].add(refTokens);
                }
            } else {
                if (refs[to] == address(0)) {
                    super._transfer(address(this), to, refTokens);
                } else {
                    super._transfer(address(this), refs[to], refTokens);
                    refRewards[refs[to]] = refRewards[refs[to]].add(refTokens);
                    refRewardsPerRef[refs[to]][to] = refRewardsPerRef[refs[to]][
                        to
                    ].add(refTokens);
                }
            }
        }

        super._transfer(from, to, amount);

        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
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

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForTokens(uint256 tokenAmount, address tokenOut)
        private
    {
        swapping = true;
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = tokenOut;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        swapping = false;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function swapTokensForCake(uint256 tokenAmount) private {
        swapping = true;
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = rewardToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        swapping = false;
    }

    function swapAndSendDividends(uint256 tokens) private {
        uint256 rewardBalanceBefore = IERC20(rewardToken).balanceOf(
            address(this)
        );
        swapTokensForCake(tokens);
        uint256 dividends = IERC20(rewardToken).balanceOf(address(this)).sub(
            rewardBalanceBefore
        );
        bool success = IERC20(rewardToken).transfer(
            address(dividendTracker),
            dividends
        );

        if (success) {
            dividendTracker.distributeCAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function burn(uint256 amount) public {
        require(
            balanceOf(msg.sender) >= amount,
            "ERC20: burn: insufficient balance"
        );
        super._burn(msg.sender, amount);
        try
            dividendTracker.setBalance(
                payable(msg.sender),
                balanceOf(msg.sender)
            )
        {} catch {}
    }

    function enableInternalTrading() external onlyOwner {
        internalTradingEnabled = true;
    }

    function buyBusd(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = BUSD;

        try
            uniswapV2Router.swapExactETHForTokens{value: amount}(
                0,
                path,
                address(this),
                block.timestamp.add(30)
            )
        {} catch {
            revert();
        }
    }

    function buy(address _ref) external payable {
        require(internalTradingEnabled, "Internal trading is not enabled");
        uint256 val = msg.value;
        purchase(val, _ref);
    }

    function purchase(uint256 bnbAmount, address ref) internal returns (bool) {
        // make sure we don't buy more than the bnb in this contract
        require(
            bnbAmount <= address(this).balance,
            "purchase not included in balance"
        );
        if (refs[msg.sender] == address(0)) {
            if (ref == address(0)) {
                refs[msg.sender] = msg.sender;
            } else {
                refs[msg.sender] = ref;
                refCount[ref] = refCount[ref].add(1);
                refList[ref].push(msg.sender);
            }
        }
        // previous amount of BUSD before we received any
        uint256 prevBusdAmount = IERC20(BUSD).balanceOf(address(this));
        // buy BUSD with the BNB we received
        buyBusd(bnbAmount);
        // if this is the first purchase, use current balance
        uint256 currentBusdAmount = IERC20(BUSD).balanceOf(address(this));
        // number of BUSD we have purchased
        uint256 difference = currentBusdAmount.sub(prevBusdAmount);
        // if this is the first purchase, use new amount
        prevBusdAmount = prevBusdAmount == 0
            ? currentBusdAmount
            : prevBusdAmount;
        // make sure total supply is greater than zero
        uint256 calculatedTotalSupply = totalSupply();
        // find the number of tokens we should mint to keep up with the current price
        uint256 nShouldPurchase = calculatedTotalSupply.mul(difference).div(
            prevBusdAmount
        );

        // apply our spread to tokens to inflate price relative to total supply
        uint256 tokensToSend = nShouldPurchase.mul(spreadDivisor).div(
            FEE_DENOMINATOR
        );

        if (tokensToSend < 1) {
            revert("Must Buy More Than One");
        }

        // mint the tokens we need to the buyer
        uint256 publicCampaginTokens = tokensToSend.mul(bPublicCampaignFee).div(
            FEE_DENOMINATOR
        );
        uint256 developmentTokens = tokensToSend.mul(bDevelopmentFee).div(
            FEE_DENOMINATOR
        );
        uint256 referralTokens = tokensToSend.mul(bReferralFee).div(
            FEE_DENOMINATOR
        );

        uint256 tokenRewardsAndLiquidityTokens = tokensToSend
            .mul(bLiquidityFee.add(bTokenRewardsFee))
            .div(FEE_DENOMINATOR);

        _mint(publicCampaignWallet, publicCampaginTokens);
        _mint(developmentWallet, developmentTokens);
        if (refs[msg.sender] != address(0)) {
            _mint(refs[msg.sender], referralTokens);
            refRewards[refs[msg.sender]] = refRewards[refs[msg.sender]].add(
                referralTokens
            );
            refRewardsPerRef[refs[msg.sender]][msg.sender] = refRewardsPerRef[
                refs[msg.sender]
            ][msg.sender].add(referralTokens);
        } else {
            _mint(msg.sender, referralTokens);
        }
        _mint(address(this), tokenRewardsAndLiquidityTokens);
        _burn(address(this), tokenRewardsAndLiquidityTokens);
        _mint(
            msg.sender,
            tokensToSend
                .sub(publicCampaginTokens)
                .sub(developmentTokens)
                .sub(referralTokens)
                .sub(tokenRewardsAndLiquidityTokens)
        );
        try
            dividendTracker.setBalance(
                payable(msg.sender),
                balanceOf(msg.sender)
            )
        {} catch {}
        return true;
    }

    function sell(uint256 tokenAmount) public returns (bool) {
        require(internalTradingEnabled, "Internal trading is not enabled");
        // make sure seller has this balance
        require(
            balanceOf(msg.sender) >= tokenAmount,
            "cannot sell above token amount"
        );
        uint256 totalFeesTokens = tokenAmount.mul(sTotalFees).div(
            FEE_DENOMINATOR
        );
        uint256 tokensToSwap = tokenAmount.sub(totalFeesTokens);
        super._transfer(
            msg.sender,
            publicCampaignWallet,
            totalFeesTokens.mul(sPublicCampaignFee).div(sTotalFees)
        );
        super._transfer(
            msg.sender,
            developmentWallet,
            totalFeesTokens.mul(sDevelopmentFee).div(sTotalFees)
        );
        if (refs[msg.sender] != address(0)) {
            super._transfer(
                msg.sender,
                refs[msg.sender],
                totalFeesTokens.mul(sReferralFee).div(sTotalFees)
            );
            refRewards[refs[msg.sender]] = refRewards[refs[msg.sender]].add(
                totalFeesTokens.mul(sReferralFee).div(sTotalFees)
            );
            refRewardsPerRef[refs[msg.sender]][msg.sender] = refRewardsPerRef[
                refs[msg.sender]
            ][msg.sender].add(
                    totalFeesTokens.mul(sReferralFee).div(sTotalFees)
                );
        } else {
            super._transfer(
                msg.sender,
                address(this),
                totalFeesTokens.mul(sReferralFee).div(sTotalFees)
            );
            super._transfer(
                address(this),
                msg.sender,
                totalFeesTokens.mul(sReferralFee).div(sTotalFees)
            );
        }
        uint256 rewardAndLiquidityTokens = totalFeesTokens
            .mul(sTokenRewardsFee.add(sLiquidityFee))
            .div(sTotalFees);
        super._transfer(msg.sender, address(this), rewardAndLiquidityTokens);
        _burn(address(this), rewardAndLiquidityTokens);

        // how much BUSD are these tokens worth?
        uint256 amountBUSD = tokensToSwap.mul(calculatePrice()).div(10**18);

        // send BUSD to Seller
        bool successful = IERC20(BUSD).transfer(msg.sender, amountBUSD);
        if (successful) {
            // subtract full amount from sender
            _burn(msg.sender, tokensToSwap);
        } else {
            revert();
        }
        return true;
    }

    function calculatePrice() public view returns (uint256) {
        uint256 busdBalance = IERC20(BUSD).balanceOf(address(this));
        return busdBalance.mul(10**18).div(totalSupply());
    }

    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    receive() external payable {}
}