// https://chibatoken.io/
// https://twitter.com/ChibaToken

// Verified using https://dapp.tools
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

contract Chiba is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public stakingWallet;
    address public devWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyStakingFee;
    uint256 public buyDevFee;

    uint256 public sellTotalFees;
    uint256 public sellStakingFee;
    uint256 public sellDevFee;

    uint256 public tokensForStaking;
    uint256 public tokensForDev;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event stakingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event devWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    bool pausedStaking = false;
    struct IStaking {
        uint256 amount;
        uint256 timestamp;
        StakingPeriod stakingPeriod;
    }
    mapping(address => IStaking) stakings;
    mapping(address => bool) stakingAvailable;
    enum StakingPeriod {
        DAILY,
        WEEKLY,
        MONTHLY
    }

    address[] staking_addresses;
    address treasuryWallet =
        address(0xA177FD5B47A50C35AAD558f8bA8105c306737cdB); // set as treasury wallet

    constructor() ERC20("A Thousand Leaves", "Chiba") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyStakingFee = 3;
        uint256 _buyDevFee = 2;

        uint256 _sellStakingFee = 3;
        uint256 _sellDevFee = 2;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransactionAmount = 20_000_000 * 1e18;
        maxWallet = 20_000_000 * 1e18;
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        buyStakingFee = _buyStakingFee;
        buyDevFee = _buyDevFee;
        buyTotalFees = buyStakingFee + buyDevFee;

        sellStakingFee = _sellStakingFee;
        sellDevFee = _sellDevFee;
        sellTotalFees = sellStakingFee + sellDevFee;

        stakingWallet = address(0xF5e24245b473caF5D206b4b85C7a41156F8F8ab9); // set as staking wallet
        devWallet = address(0x05056Ccccdf4A1DA7C0538CE97f5D7834933A35B); // set as dev wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    function updateTokenSettings(
        uint256 _maxTransactionAmount,
        uint256 _maxWallet,
        bool _limitsInEffect
    ) external onlyOwner {
        require(
            _maxTransactionAmount >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        require(
            _maxWallet >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxTransactionAmount = _maxTransactionAmount * (10**18);
        maxWallet = _maxWallet * (10**18);
        limitsInEffect = _limitsInEffect;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateFees(
        uint256 _buyStakingFee,
        uint256 _buyDevFee,
        uint256 _sellStakingFee,
        uint256 _sellDevFee
    ) external onlyOwner {
        buyStakingFee = _buyStakingFee;
        buyDevFee = _buyDevFee;
        buyTotalFees = buyStakingFee + buyDevFee;

        sellStakingFee = _sellStakingFee;
        sellDevFee = _sellDevFee;
        sellTotalFees = sellStakingFee + sellDevFee;

        require(buyTotalFees <= 10, "Must keep fees at 10% or less");
        require(sellTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
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

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                tokensForStaking += (fees * sellStakingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForStaking += (fees * buyStakingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees - tokensForStaking);
                super._transfer(from, stakingWallet, tokensForStaking);
                tokensForStaking = 0;
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
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
        uint256 totalTokensToSwap = tokensForDev;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }
        uint256 amountToSwapForETH = contractBalance;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        tokensForDev = 0;

        (success, ) = address(devWallet).call{value: ethBalance}("");
    }

    // <--------------------------- Staking logic --------------------------->

    function getStaking(address staker) public view returns (IStaking memory) {
        return stakings[staker];
    }

    function hasStaken(address staker) public view returns (bool) {
        return stakingAvailable[staker];
    }

    function updateStakingStatus(bool _status) external onlyOwner {
        pausedStaking = _status;
    }

    function isPausedStaking() public view returns (bool) {
        return pausedStaking;
    }

    function getStakingPeriodLeft(address staker)
        public
        view
        returns (uint256)
    {
        IStaking memory staking = stakings[staker];
        if (staking.stakingPeriod == StakingPeriod.DAILY) {
            return (staking.timestamp + 1 days) - block.timestamp;
        } else if (staking.stakingPeriod == StakingPeriod.WEEKLY) {
            return (staking.timestamp + 7 days) - block.timestamp;
        } else {
            return (staking.timestamp + 30 days) - block.timestamp;
        }
    }

    function allowedWithdrawal(address staker) public view returns (bool) {
        require(hasStaken(staker), "Staking instance not available");
        IStaking memory staking = stakings[staker];
        if (staking.stakingPeriod == StakingPeriod.DAILY) {
            return block.timestamp >= staking.timestamp + 1 days;
        } else if (staking.stakingPeriod == StakingPeriod.WEEKLY) {
            return block.timestamp >= staking.timestamp + 7 days;
        } else {
            return block.timestamp >= staking.timestamp + 30 days;
        }
    }

    function existingStakerAddress(address staker) public view returns (bool) {
        for (uint256 i = 0; i < staking_addresses.length; i++) {
            if (staking_addresses[i] == staker) {
                return true;
            }
        }
        return false;
    }

    function getStakers() public view returns (address[] memory) {
        return staking_addresses;
    }

    function stakeTokens(StakingPeriod stakingPeriod, uint256 tokens) external {
        require(!isPausedStaking(), "Staking is paused");
        require(
            stakingPeriod == StakingPeriod.DAILY ||
                stakingPeriod == StakingPeriod.WEEKLY ||
                stakingPeriod == StakingPeriod.MONTHLY,
            "Enum not specified"
        );
        require(tokens > 0, "Tokens need to be grater than zero");
        require(
            balanceOf(msg.sender) >= tokens && balanceOf(msg.sender) > 0,
            "Tokens exceeding balance"
        );
        require(!hasStaken(msg.sender), "Staking instance already available");
        stakingAvailable[msg.sender] = true;
        IStaking memory staking = IStaking(
            tokens,
            block.timestamp,
            stakingPeriod
        );
        super._transfer(msg.sender, treasuryWallet, tokens);
        stakings[msg.sender] = staking;
        if (!existingStakerAddress(msg.sender)) {
            staking_addresses.push(msg.sender);
        }
    }

    function _withdrawStaking(address sender) internal {
        super._transfer(treasuryWallet, sender, stakings[sender].amount);
        stakings[sender].amount = 0;
        stakings[sender].timestamp = 0;
        stakingAvailable[sender] = false;
    }

    function getClaimableReward(address staker) public view returns (uint256) {
        uint256 dividend = (stakings[staker].amount)
            .mul(balanceOf(stakingWallet))
            .mul(getStakingPeriodPercentage(stakings[staker].stakingPeriod));
        uint256 diviser = (totalSupply()).mul(100);
        return dividend.div(diviser);
    }

    function claimReward() external {
        require(!isPausedStaking(), "Staking is paused");
        require(hasStaken(msg.sender), "Staking not available");
        require(getClaimableReward(msg.sender) > 0, "No tokens to be claimed");
        require(
            allowedWithdrawal(msg.sender),
            "Staking period has not ended yet"
        );
        uint256 claimable = getClaimableReward(msg.sender);
        super._transfer(stakingWallet, msg.sender, claimable);
        _withdrawStaking(msg.sender);
    }

    function getStakingPeriodPercentage(StakingPeriod stakingPeriod)
        public
        view
        returns (uint256)
    {
        if (stakingPeriod == StakingPeriod.DAILY) {
            return 25;
        } else if (stakingPeriod == StakingPeriod.WEEKLY) {
            return 50;
        } else {
            return 100;
        }
    }
}