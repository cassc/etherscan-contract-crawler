//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./libs/UniversalERC20.sol";

// File: contracts/GameHubPaymentGateway.sol

contract GameHubPaymentGateway is OwnableUpgradeable, PausableUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;

    struct OracleData {
        bool usdPaired;
        address pairToken;
        address proxy;
        uint8 feedDecimals;
    }

    uint16 private constant DELIMINATOR = 10000;

    /** Fee distribution logic */
    uint16 public _marketingRate;
    uint16 public _treasuryRate;
    uint16 public _charityRate;

    uint256 public _gameCoinPrice; // Game coin price in usd, decimal 18

    /** Min / max limitation per deposit (it is calculated in unit token) */
    uint256 public _maxDepositAmount;
    uint256 public _minDepositAmount;

    /** Wallet addresses for distributing deposited funds */
    address public _marketingWallet;
    address public _treasuryWallet;
    address public _charityWallet;

    /** Accounts blocked to deposit */
    mapping(address => bool) public _accountBlacklist;
    /** Tokens whitelisted for deposit */
    mapping(address => bool) public _tokenWhitelist;
    mapping(address => OracleData) public _oracles;

    event NewDeposit(
        address indexed account,
        address indexed payToken, // paid token
        uint256 payAmount, // paid token amount
        uint256 usdAmount, // paid usd amount
        uint256 gameCoinAmount // game coin amount allocated to the user
    );
    event NewDistribute(
        address indexed account,
        address indexed token,
        uint256 marketingAmount,
        uint256 treasuryAmount,
        uint256 charityAmount
    );
    event NewAccountBlacklist(address indexed account, bool blacklisted);
    event NewTokenWhitelist(address indexed token, bool whitelisted);

    function initialize(
        address marketingWallet,
        address treasuryWallet,
        address charityWallet
    ) public initializer {
        __Pausable_init();
        __Ownable_init();

        _marketingWallet = marketingWallet;
        _treasuryWallet = treasuryWallet;
        _charityWallet = charityWallet;

        _marketingRate = 3000;
        _treasuryRate = 2000;
        _charityRate = 5000;
    }

    /**
     * @dev To receive ETH
     */
    receive() external payable {}

    /**
     * @notice Deposit tokens to get game coins
     * @dev Only available when gateway is not paused
     * @param tokenIn_: deposit token, must whitelisted, allow native token (0x0)
     */
    function deposit(address tokenIn_, uint256 amountIn_)
        external
        payable
        whenNotPaused
    {
        require(!_accountBlacklist[_msgSender()], "Blacklisted account");
        require(_tokenWhitelist[tokenIn_], "Token not whitelisted");

        IERC20Upgradeable payingToken = IERC20Upgradeable(tokenIn_);
        amountIn_ = payingToken.universalTransferFrom(
            _msgSender(),
            address(this),
            amountIn_
        );

        distributeToken(IERC20Upgradeable(tokenIn_), amountIn_);
        (uint256 usdAmount, uint256 gameCoinAmount) = viewConversion(
            tokenIn_,
            amountIn_
        );

        require(gameCoinAmount > 0, "No balance to deposit");

        require(
            _minDepositAmount == 0 || _minDepositAmount <= gameCoinAmount,
            "Too small amount"
        );
        require(
            _maxDepositAmount == 0 || _maxDepositAmount >= gameCoinAmount,
            "Too much amount"
        );

        emit NewDeposit(
            _msgSender(),
            tokenIn_,
            amountIn_,
            usdAmount,
            gameCoinAmount
        );
    }

    /**
     * @notice View converted amount in unit token, and game coin amount
     * @return usdAmount_ USD amount in decimal 18
     * @return gameCoinAmount_ Game coin amount in real value
     */
    function viewConversion(address token_, uint256 amount_)
        public
        view
        returns (uint256 usdAmount_, uint256 gameCoinAmount_)
    {
        uint256 latestPrice = getLatestPrice(token_);
        usdAmount_ =
            (amount_ * latestPrice) /
            (10**IERC20Upgradeable(token_).universalDecimals());
        gameCoinAmount_ = usdAmount_ / _gameCoinPrice;
    }

    /**
     * @notice Returns the latest price
     * @param token_: Token to get price
     * @return tokenPrice : Token price in decimal 18
     */
    function getLatestPrice(address token_)
        public
        view
        returns (uint256 tokenPrice)
    {
        OracleData memory oracleData = _oracles[token_];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            oracleData.proxy
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /* uint startedAt */ /* uint timeStamp */ /* uint80 answeredInRound */
            ,
            ,

        ) = priceFeed.latestRoundData();
        tokenPrice = (uint256(price) * 10**18) / (10**oracleData.feedDecimals);
        // Check if token feed with usd
        if (!oracleData.usdPaired) {
            // Get feed of current paired token
            OracleData memory pairOracleData = _oracles[oracleData.pairToken];
            require(pairOracleData.usdPaired, "Pair oracle not usd feed");
            AggregatorV3Interface pairPriceFeed = AggregatorV3Interface(
                pairOracleData.proxy
            );
            (
                ,
                /*uint80 roundID*/
                int256 pairPrice, /* uint startedAt */ /* uint timeStamp */ /* uint80 answeredInRound */
                ,
                ,

            ) = pairPriceFeed.latestRoundData();
            tokenPrice =
                (tokenPrice * uint256(pairPrice)) /
                (10**pairOracleData.feedDecimals);
        }
    }

    /**
     * @notice Distribute token as the distribution rates
     */
    function distributeToken(IERC20Upgradeable token_, uint256 amount_)
        internal
    {
        uint256 marketingAmount = (amount_ * _marketingRate) / DELIMINATOR;
        uint256 treasuryAmount = (amount_ * _treasuryRate) / DELIMINATOR;
        uint256 charityAmount = amount_ - marketingAmount - treasuryAmount;

        if (marketingAmount > 0) {
            token_.universalTransfer(_marketingWallet, marketingAmount);
        }
        if (charityAmount > 0) {
            token_.universalTransfer(_charityWallet, charityAmount);
        }
        if (treasuryAmount > 0) {
            token_.universalTransfer(_treasuryWallet, treasuryAmount);
        }
        emit NewDistribute(
            _msgSender(),
            address(token_),
            marketingAmount,
            treasuryAmount,
            charityAmount
        );
    }

    /**
     * @notice Update oracle data for the token
     */
    function updateOracleData(
        address token_,
        address pairToken_,
        address priceFeed_,
        uint8 feedDecimals_,
        bool isUsdPaired_
    ) external onlyOwner {
        OracleData storage oracleData = _oracles[token_];
        oracleData.pairToken = pairToken_;
        oracleData.proxy = priceFeed_;
        oracleData.feedDecimals = feedDecimals_;
        oracleData.usdPaired = isUsdPaired_;
    }

    /**
     * @notice Block account from deposit or not
     * @dev Only owner can call this function
     */
    function blockAccount(address account_, bool flag_) external onlyOwner {
        _accountBlacklist[account_] = flag_;

        emit NewAccountBlacklist(account_, flag_);
    }

    /**
     * @notice Allow token for deposit or not
     * @dev Only owner can call this function
     */
    function allowToken(address token_, bool flag_) external onlyOwner {
        _tokenWhitelist[token_] = flag_;

        emit NewTokenWhitelist(token_, flag_);
    }

    /**
     * @notice Set deposit min / max limit
     * @dev Only owner can call this function
     */
    function setDepositLimit(uint256 minAmount_, uint256 maxAmount_)
        external
        onlyOwner
    {
        _minDepositAmount = minAmount_;
        _maxDepositAmount = maxAmount_;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pauseGateway() external onlyOwner {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpauseGateway() external onlyOwner {
        super._unpause();
    }

    /**
     * @notice Set unit token and the rate of unit token to game coin
     * @param rate_: Game coin price in decimal 18
     * @dev Only owner can call this function
     */
    function setGameCoinRate(uint256 rate_) external onlyOwner {
        require(rate_ > 0, "Invalid rates to game coin");
        _gameCoinPrice = rate_;
    }

    /**
     * @notice Set distribution rates, sum of the params should be 100% (10000)
     * @dev Only owner can call this function
     */
    function setDistributionRates(
        uint16 marketingRate_,
        uint16 treasuryRate_,
        uint16 charityRate_
    ) external onlyOwner {
        require(
            marketingRate_ + treasuryRate_ + charityRate_ == DELIMINATOR,
            "Invalid values"
        );
        _marketingRate = marketingRate_;
        _treasuryRate = treasuryRate_;
        _charityRate = charityRate_;
    }

    /**
     * @notice Set distribution wallets
     * @dev Only owner can call this function
     */
    function setDistributionWallets(
        address marketingWallet_,
        address treasuryWallet_,
        address charityWallet_
    ) external onlyOwner {
        require(marketingWallet_ != address(0), "Invalid marketing wallet");
        require(treasuryWallet_ != address(0), "Invalid treasury wallet");
        require(charityWallet_ != address(0), "Invalid charity wallet");
        _marketingWallet = marketingWallet_;
        _treasuryWallet = treasuryWallet_;
        _charityWallet = charityWallet_;
    }

    /**
     * @notice It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverTokens(address token_, uint256 amount_) external onlyOwner {
        IERC20Upgradeable(token_).universalTransfer(_msgSender(), amount_);
    }
}