// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./interfaces/IIndexHelper.sol";
import "./interfaces/IIndexRouter.sol";
import "./interfaces/IIndexBettingViewer.sol";
import "./interfaces/IIndexBettingManager.sol";
import "./interfaces/IIndexBetting.sol";

contract IndexBetting is
    IIndexBetting,
    IIndexBettingViewer,
    IIndexBettingManager,
    ERC20PermitUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using FixedPointMathLib for uint256;
    using SafeCast for uint256;

    /// @notice Base point number
    uint16 internal constant BP = 10_000;

    /// @notice Number of decimals in base asset
    uint8 internal constant BASE_DECIMALS = 6;

    /// @notice Number of decimals in base asset answer
    uint8 internal constant BASE_AGGREGATOR_DECIMALS = 8;

    /// @inheritdoc IIndexBettingViewer
    IERC20MetadataUpgradeable public constant override REWARD_TOKEN =
        IERC20MetadataUpgradeable(0x632806BF5c8f062932Dd121244c9fbe7becb8B48);

    /// @inheritdoc IIndexBettingViewer
    IERC20MetadataUpgradeable public constant override STAKING_TOKEN =
        IERC20MetadataUpgradeable(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b);

    /// @inheritdoc IIndexBettingViewer
    uint16 public constant override VICTORY_REWARD_RATE = 500;

    /// @inheritdoc IIndexBettingViewer
    uint16 public constant override DEFEAT_REWARD_RATE = 200;

    /// @inheritdoc IIndexBettingViewer
    IIndexRouter public constant override INDEX_ROUTER = IIndexRouter(0x1985426d77c431fc95E5Ca51547BcB9b793E8482);

    /// @inheritdoc IIndexBettingViewer
    AggregatorV3Interface public immutable override DPI_PRICE_FEED;

    /// @inheritdoc IIndexBettingViewer
    IIndexHelper public immutable override INDEX_HELPER;

    /// @inheritdoc IIndexBettingViewer
    Epoch public override startEpoch;

    /// @inheritdoc IIndexBettingViewer
    Epoch public override endEpoch;

    /// @inheritdoc IIndexBettingViewer
    uint32 public override frontRunningLockupDuration;

    /// @inheritdoc IIndexBettingViewer
    uint128 public override maxStakingAmount;

    /// @inheritdoc IIndexBettingViewer
    uint16 public override PDIRewardRate;

    /// @inheritdoc IIndexBettingViewer
    uint80 public override DPIRoundID;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(AggregatorV3Interface _dpiPriceFeed, IIndexHelper _indexHelper) {
        DPI_PRICE_FEED = _dpiPriceFeed;
        INDEX_HELPER = _indexHelper;
        _disableInitializers();
    }

    /// @notice Checks if PDIRewardRate has been set
    modifier checkPDIRewardRate() {
        require(PDIRewardRate != 0, "IndexBetting: FORBIDDEN");
        _;
    }

    /// @inheritdoc IIndexBetting
    function initialize(string calldata _name, string calldata _symbol, uint256 _maxTVLAmountInBase)
        external
        override
        initializer
    {
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        STAKING_TOKEN.safeApprove(address(INDEX_ROUTER), type(uint256).max);
        maxStakingAmount = _getStakingAmount(_maxTVLAmountInBase);
    }

    /*
    IndexBetting management functions
    */

    /// @inheritdoc IIndexBettingManager
    function startBettingChallenge(uint256 _challengeDuration, uint32 _frontRunningLockupDuration)
        external
        override
        onlyOwner
    {
        require(_challengeDuration > _frontRunningLockupDuration && PDIRewardRate == 0, "IndexBetting: INVALID");

        frontRunningLockupDuration = _frontRunningLockupDuration;
        startEpoch = Epoch(block.timestamp.toUint32(), getLatestPDIPrice(), getLatestDPIPrice());
        endEpoch = Epoch((block.timestamp + _challengeDuration).toUint32(), 0, 0);

        emit BettingChallengeStarted(_frontRunningLockupDuration, block.timestamp, block.timestamp + _challengeDuration);
    }

    /*
    External functions
    */

    /// @inheritdoc IIndexBetting
    function deposit(uint256 _assets) external override {
        require(
            (startEpoch.timestamp == 0 || endEpoch.timestamp - frontRunningLockupDuration > block.timestamp)
                && _assets + totalSupply() <= maxStakingAmount,
            "IndexBetting: INVALID"
        );
        STAKING_TOKEN.safeTransferFrom(msg.sender, address(this), _assets);
        _mint(msg.sender, _assets);
    }

    /// @inheritdoc IIndexBetting
    function withdraw() external override nonReentrant checkPDIRewardRate {
        uint256 assets = balanceOf(msg.sender);
        require(assets > 0, "IndexBetting: ZERO");
        _burn(msg.sender, assets);
        // In case of victory withdrawing without conversion to PDI does not transfer rewards
        if (PDIRewardRate == DEFEAT_REWARD_RATE) {
            uint256 rewardAmount = getReward(assets, DEFEAT_REWARD_RATE);
            REWARD_TOKEN.safeTransfer(msg.sender, rewardAmount);
        }
        STAKING_TOKEN.safeTransfer(msg.sender, assets);
    }

    /// @inheritdoc IIndexBetting
    function withdrawAndMint(IIndexRouter.MintQuoteParams[] calldata _quotes)
        external
        override
        nonReentrant
        checkPDIRewardRate
    {
        (uint256 assets, uint256 rewardAmount) = _burnAndGetReward(msg.sender);
        uint256 assetBalanceBefore = STAKING_TOKEN.balanceOf(address(this));
        INDEX_ROUTER.mintSwap(
            IIndexRouter.MintSwapParams({
                index: address(REWARD_TOKEN), // PDI
                inputToken: address(STAKING_TOKEN), // DPI
                amountInInputToken: assets,
                recipient: msg.sender,
                quotes: _quotes
            })
        );
        uint256 assetBalanceAfter = STAKING_TOKEN.balanceOf(address(this));
        require(assetBalanceBefore - assetBalanceAfter == assets, "IndexBetting: MAX");
        REWARD_TOKEN.safeTransfer(msg.sender, rewardAmount);
    }

    /// @inheritdoc IIndexBetting
    function withdrawAndSwap(address _swapTarget, bytes calldata _assetQuote, uint256 _minBuyAmount)
        external
        override
        nonReentrant
        checkPDIRewardRate
    {
        (uint256 assets, uint256 rewardAmount) = _burnAndGetReward(msg.sender);
        uint256 assetBalanceBefore = STAKING_TOKEN.balanceOf(address(this));
        uint256 balanceOfIndexBefore = REWARD_TOKEN.balanceOf(address(this));
        STAKING_TOKEN.safeApprove(_swapTarget, assets);
        _fillQuote(_swapTarget, _assetQuote);
        uint256 balanceOfIndexAfter = REWARD_TOKEN.balanceOf(address(this));
        require(balanceOfIndexAfter - balanceOfIndexBefore >= _minBuyAmount, "IndexBetting: MIN");
        uint256 assetBalanceAfter = STAKING_TOKEN.balanceOf(address(this));
        require(assetBalanceBefore - assetBalanceAfter == assets, "IndexBetting: MAX");
        STAKING_TOKEN.safeApprove(_swapTarget, 0);
        REWARD_TOKEN.safeTransfer(msg.sender, balanceOfIndexAfter - balanceOfIndexBefore + rewardAmount);
    }

    /// @inheritdoc IIndexBetting
    function setChallengeOutcomeForRoundId() external override {
        // This can be called after setChallengeOutcome has been called and roundId has been saved.
        // If it sets the PDIReward rate then it cannot be called again.
        require(DPIRoundID != 0 && PDIRewardRate == 0, "IndexBetting: INVALID");
        (uint80 _roundID,,,,) = DPI_PRICE_FEED.latestRoundData();
        require(_roundID > DPIRoundID, "IndexBetting: INVALID");
        (uint80 roundID, int256 price,, uint256 updatedAt, uint80 answeredInRound) =
            DPI_PRICE_FEED.getRoundData(DPIRoundID + 1);
        require(updatedAt != 0 && price > 0 && answeredInRound >= roundID, "IndexBetting: STALE");
        _setPDIRewardRate(price);
    }

    /// @inheritdoc IIndexBetting
    function setChallengeOutcome() external override {
        require(block.timestamp >= endEpoch.timestamp && PDIRewardRate == 0 && DPIRoundID == 0, "IndexBetting: INVALID");
        (uint80 roundID, int256 price,, uint256 updatedAt, uint80 answeredInRound) = DPI_PRICE_FEED.latestRoundData();
        require(updatedAt != 0 && price > 0 && answeredInRound >= roundID, "IndexBetting: STALE");
        // This is executable only once after the challenge has ended and it either sets the PDIReward rate or the DPIRoundID.
        if (updatedAt > endEpoch.timestamp) {
            _setPDIRewardRate(price);
        } else {
            DPIRoundID = roundID;
        }
    }

    /*
    Internal functions
    */

    /// @notice Burns shares from user and returns the award amount.
    function _burnAndGetReward(address _user) internal returns (uint256 assets, uint256 rewardAmount) {
        assets = balanceOf(_user);
        require(assets > 0, "IndexBetting: ZERO");
        _burn(_user, assets);
        // While withdrawing with conversion the reward rate always equals to the victory reward rate.
        rewardAmount = getReward(assets, VICTORY_REWARD_RATE);
        // early revert to save gas
        require(REWARD_TOKEN.balanceOf(address(this)) >= rewardAmount, "IndexBetting: FORBIDDEN");
    }

    /// @notice Sets the PDIRewardRate based on the start and end prices of DPI and PDI.
    function _setPDIRewardRate(int256 _DPIPrice) internal {
        endEpoch.PDIPrice = getLatestPDIPrice();
        endEpoch.DPIPrice = uint256(_DPIPrice).toUint112();
        PDIRewardRate = (endEpoch.PDIPrice * 10 ** BASE_AGGREGATOR_DECIMALS) / startEpoch.PDIPrice
            >= (endEpoch.DPIPrice * 10 ** BASE_AGGREGATOR_DECIMALS) / startEpoch.DPIPrice
            ? VICTORY_REWARD_RATE
            : DEFEAT_REWARD_RATE;
    }

    /// @notice Fills the quote for the `_swapTarget` with the `quote`
    /// @param _swapTarget Swap target address
    /// @param _quote Quote to fill
    function _fillQuote(address _swapTarget, bytes calldata _quote) internal {
        (bool success, bytes memory returnData) = _swapTarget.call(_quote);
        if (!success) {
            if (returnData.length == 0) {
                revert("IndexBetting: SWAP");
            } else {
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            }
        }
    }

    /// @notice Calculates amount of staking token based on the value in base token
    function _getStakingAmount(uint256 _TVLAmountInBase) internal view returns (uint128) {
        return (
            (_TVLAmountInBase * (10 ** (BASE_AGGREGATOR_DECIMALS - BASE_DECIMALS))).mulDivDown(
                10 ** STAKING_TOKEN.decimals(), getLatestDPIPrice()
            )
        ).toUint128();
    }

    /*
    View functions
    */

    /// @inheritdoc IIndexBettingViewer
    function getLatestDPIPrice() public view override returns (uint112) {
        (uint80 roundID, int256 price,, uint256 updatedAt, uint80 answeredInRound) = DPI_PRICE_FEED.latestRoundData();
        if (updatedAt == 0 || price < 1 || answeredInRound < roundID) {
            if (roundID != 0) {
                (roundID, price,, updatedAt, answeredInRound) = DPI_PRICE_FEED.getRoundData(roundID - 1);
            }

            require(updatedAt != 0 && price > 0 && answeredInRound >= roundID, "IndexBetting: STALE");
        }
        return uint256(price).toUint112();
    }

    /// @inheritdoc IIndexBettingViewer
    function getLatestPDIPrice() public view override returns (uint112) {
        (, uint256 PDIValueInBase) = INDEX_HELPER.totalEvaluation(address(REWARD_TOKEN));
        return (PDIValueInBase * 10 ** (BASE_AGGREGATOR_DECIMALS - BASE_DECIMALS)).toUint112();
    }

    /// @inheritdoc IIndexBettingViewer
    function getCurrentRewardRate() public view override returns (uint16 _PDIRewardRate) {
        uint112 _startPDIPrice = startEpoch.PDIPrice;
        uint112 _startDPIPrice = startEpoch.DPIPrice;
        if (_startPDIPrice == 0 || _startDPIPrice == 0) {
            return 0;
        }
        _PDIRewardRate = (getLatestPDIPrice() * 10 ** BASE_AGGREGATOR_DECIMALS) / _startPDIPrice
            >= (getLatestDPIPrice() * 10 ** BASE_AGGREGATOR_DECIMALS) / _startDPIPrice
            ? VICTORY_REWARD_RATE
            : DEFEAT_REWARD_RATE;
    }

    /// @inheritdoc IIndexBettingViewer
    function getCurrentRewardAmount(address user) public view override returns (uint256) {
        return getReward(balanceOf(user), getCurrentRewardRate());
    }

    /// @inheritdoc IIndexBettingViewer
    function getCurrentTotalRewardAmount() public view override returns (uint256) {
        return getReward(totalSupply(), getCurrentRewardRate());
    }

    /// @inheritdoc IIndexBettingViewer
    function getSettledTotalRewardAmount() public view override returns (uint256) {
        return getReward(totalSupply(), PDIRewardRate);
    }

    /// @inheritdoc IIndexBettingViewer
    function getSettledRewardAmount(address _user) public view override returns (uint256) {
        return getReward(balanceOf(_user), PDIRewardRate);
    }

    /// @inheritdoc IIndexBettingViewer
    function getReward(uint256 _amount, uint16 _PDIRewardRate) public view override returns (uint256) {
        uint256 _startPDIPrice = startEpoch.PDIPrice;
        uint256 _startDPIPrice = startEpoch.DPIPrice;
        if (_startPDIPrice == 0 || _startDPIPrice == 0) {
            return 0;
        }
        return (_amount * _startDPIPrice * _PDIRewardRate) / (_startPDIPrice * BP);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyOwner {}

    uint256[47] private __gap;
}