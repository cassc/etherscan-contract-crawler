// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "../interfaces/IPositionalMarketManager.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// Libraries
import "../utils/libraries/AddressSetLib.sol";
import "../utils/libraries/DateTime.sol";
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./PositionalMarketFactory.sol";
import "./PositionalMarket.sol";
import "./Position.sol";
import "../interfaces/IPositionalMarket.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IThalesAMM.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PositionalMarketManager is Initializable, ProxyOwned, ProxyPausable, IPositionalMarketManager {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;
    using AddressSetLib for AddressSetLib.AddressSet;

    /* ========== TYPES ========== */

    struct Fees {
        uint poolFee;
        uint creatorFee;
    }

    struct Durations {
        uint expiryDuration;
        uint maxTimeToMaturity;
    }

    /* ========== STATE VARIABLES ========== */

    Durations public override durations;
    uint public override capitalRequirement;

    bool public override marketCreationEnabled;
    bool public customMarketCreationEnabled;

    bool public onlyWhitelistedAddressesCanCreateMarkets;
    mapping(address => bool) public whitelistedAddresses;

    uint public override totalDeposited;

    AddressSetLib.AddressSet internal _activeMarkets;
    AddressSetLib.AddressSet internal _maturedMarkets;

    PositionalMarketManager internal _migratingManager;

    IPriceFeed public priceFeed;
    IERC20 public sUSD;

    address public positionalMarketFactory;

    bool public needsTransformingCollateral;

    uint public timeframeBuffer;
    uint256 public priceBuffer;

    mapping(bytes32 => mapping(uint => address[])) public marketsPerOracleKey;
    mapping(address => uint) public marketsStrikePrice;

    bool public override onlyAMMMintingAndBurning;

    function initialize(
        address _owner,
        IERC20 _sUSD,
        IPriceFeed _priceFeed,
        uint _expiryDuration,
        uint _maxTimeToMaturity
    ) external initializer {
        setOwner(_owner);
        priceFeed = _priceFeed;
        sUSD = _sUSD;

        // Temporarily change the owner so that the setters don't revert.
        owner = msg.sender;

        marketCreationEnabled = true;
        customMarketCreationEnabled = false;
        onlyWhitelistedAddressesCanCreateMarkets = false;

        setExpiryDuration(_expiryDuration);
        setMaxTimeToMaturity(_maxTimeToMaturity);
    }

    /// @notice isKnownMarket checks if market is among matured or active markets
    /// @param candidate Address of the market.
    /// @return bool
    function isKnownMarket(address candidate) public view override returns (bool) {
        return _activeMarkets.contains(candidate) || _maturedMarkets.contains(candidate);
    }

    /// @notice isActiveMarket checks if market is active market
    /// @param candidate Address of the market.
    /// @return bool
    function isActiveMarket(address candidate) public view override returns (bool) {
        return _activeMarkets.contains(candidate);
    }

    /// @notice numActiveMarkets returns number of active markets
    /// @return uint
    function numActiveMarkets() external view override returns (uint) {
        return _activeMarkets.elements.length;
    }

    /// @notice activeMarkets returns list of active markets
    /// @param index index of the page
    /// @param pageSize number of addresses per page
    /// @return address[] active market list
    function activeMarkets(uint index, uint pageSize) external view override returns (address[] memory) {
        return _activeMarkets.getPage(index, pageSize);
    }

    /// @notice numMaturedMarkets returns number of mature markets
    /// @return uint
    function numMaturedMarkets() external view override returns (uint) {
        return _maturedMarkets.elements.length;
    }

    /// @notice maturedMarkets returns list of matured markets
    /// @param index index of the page
    /// @param pageSize number of addresses per page
    /// @return address[] matured market list
    function maturedMarkets(uint index, uint pageSize) external view override returns (address[] memory) {
        return _maturedMarkets.getPage(index, pageSize);
    }

    /// @notice incrementTotalDeposited increments totalDeposited value
    /// @param delta increment amount
    function incrementTotalDeposited(uint delta) external onlyActiveMarkets notPaused {
        totalDeposited = totalDeposited.add(delta);
    }

    /// @notice decrementTotalDeposited decrements totalDeposited value
    /// @dev As individual market debt is not tracked here, the underlying markets
    /// need to be careful never to subtract more debt than they added.
    /// This can't be enforced without additional state/communication overhead.
    /// @param delta decrement amount
    function decrementTotalDeposited(uint delta) external onlyKnownMarkets notPaused {
        totalDeposited = totalDeposited.sub(delta);
    }

    /// @notice createMarket create market function
    /// @param oracleKey market oracle key
    /// @param strikePrice market strike price
    /// @param maturity  market maturity date
    /// @param initialMint initial sUSD to mint options for
    /// @return IPositionalMarket created market
    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint
    )
        external
        override
        notPaused
        returns (
            IPositionalMarket // no support for returning PositionalMarket polymorphically given the interface
        )
    {
        if (onlyWhitelistedAddressesCanCreateMarkets) {
            require(whitelistedAddresses[msg.sender], "Only whitelisted addresses can create markets");
        }

        (bool canCreate, string memory message) = canCreateMarket(oracleKey, maturity, strikePrice);
        require(canCreate, message);

        uint expiry = maturity.add(durations.expiryDuration);

        PositionalMarket market = PositionalMarketFactory(positionalMarketFactory).createMarket(
            PositionalMarketFactory.PositionCreationMarketParameters(
                msg.sender,
                sUSD,
                priceFeed,
                oracleKey,
                strikePrice,
                [maturity, expiry],
                initialMint
            )
        );

        _activeMarkets.add(address(market));

        // The debt can't be incremented in the new market's constructor because until construction is complete,
        // the manager doesn't know its address in order to grant it permission.
        totalDeposited = totalDeposited.add(initialMint);
        sUSD.transferFrom(msg.sender, address(market), _transformCollateral(initialMint));

        (IPosition up, IPosition down) = market.getOptions();

        marketsStrikePrice[address(market)] = strikePrice;
        marketsPerOracleKey[oracleKey][_getDateFromTimestamp(maturity)].push(address(market));

        emit MarketCreated(
            address(market),
            msg.sender,
            oracleKey,
            strikePrice,
            maturity,
            expiry,
            address(up),
            address(down),
            false,
            address(0)
        );
        return market;
    }

    /// @notice transferSusdTo transfers sUSD from market to receiver
    /// @dev Only to be called by markets themselves
    /// @param sender address of sender
    /// @param receiver address of receiver
    /// @param amount amount to be transferred
    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external override {
        //only to be called by markets themselves
        require(isKnownMarket(address(msg.sender)), "Market unknown.");
        bool success = sUSD.transferFrom(sender, receiver, amount);
        if (!success) {
            revert("TransferFrom function failed");
        }
    }

    /// @notice resolveMarket resolves an active market
    /// @param market address of the market
    function resolveMarket(address market) external override {
        require(_activeMarkets.contains(market), "Not an active market");
        PositionalMarket(market).resolve();
        _activeMarkets.remove(market);
        _maturedMarkets.add(market);
    }

    /// @notice expireMarkets removes expired markets from matured markets
    /// @param markets array of market addresses
    function expireMarkets(address[] calldata markets) external override notPaused onlyOwner {
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];

            require(isKnownMarket(address(market)), "Market unknown.");

            // The market itself handles decrementing the total deposits.
            PositionalMarket(market).expire(payable(msg.sender));

            // Note that we required that the market is known, which guarantees
            // its index is defined and that the list of markets is not empty.
            _maturedMarkets.remove(market);

            emit MarketExpired(market);
        }
    }

    /// @notice transformCollateral transforms collateral
    /// @param value value to be transformed
    /// @return uint
    function transformCollateral(uint value) external view override returns (uint) {
        return _transformCollateral(value);
    }

    /// @notice reverseTransformCollateral reverse collateral if needed
    /// @param value value to be reversed
    /// @return uint
    function reverseTransformCollateral(uint value) external view override returns (uint) {
        if (needsTransformingCollateral) {
            return value * 1e12;
        } else {
            return value;
        }
    }

    /// @notice canCreateMarket checks if market can be created
    /// @param oracleKey market oracle key
    /// @param maturity market maturity timestamp
    /// @param strikePrice market strike price
    /// @return bool
    function canCreateMarket(
        bytes32 oracleKey,
        uint maturity,
        uint strikePrice
    ) public view returns (bool, string memory) {
        if (!marketCreationEnabled) {
            return (false, "Market creation is disabled");
        }

        if (!_isValidKey(oracleKey)) {
            return (false, "Invalid key");
        }

        if (maturity > block.timestamp + durations.maxTimeToMaturity) {
            return (false, "Maturity too far in the future");
        }

        if (block.timestamp >= maturity) {
            return (false, "Maturity too far in the future");
        }

        if (!_checkMarkets(oracleKey, strikePrice, maturity)) {
            return (false, "A market already exists within that timeframe and price buffer");
        }

        return (true, "");
    }

    /// @notice enableWhitelistedAddresses enables option that only whitelisted addresses
    /// can create markets
    function enableWhitelistedAddresses() external onlyOwner {
        onlyWhitelistedAddressesCanCreateMarkets = true;
    }

    /// @notice disableWhitelistedAddresses disables option that only whitelisted addresses
    /// can create markets
    function disableWhitelistedAddresses() external onlyOwner {
        onlyWhitelistedAddressesCanCreateMarkets = false;
    }

    /// @notice addWhitelistedAddress adds given address to whitelisted addresses list
    /// @param _address address to be added to the list
    function addWhitelistedAddress(address _address) external onlyOwner {
        whitelistedAddresses[_address] = true;
    }

    /// @notice removeWhitelistedAddress removes given address from whitelisted addresses list
    /// @param _address address to be removed from the list
    function removeWhitelistedAddress(address _address) external onlyOwner {
        delete whitelistedAddresses[_address];
    }

    /// @notice setWhitelistedAddresses enables whitelist addresses option and creates list
    /// @param _whitelistedAddresses array of whitelisted addresses
    function setWhitelistedAddresses(address[] calldata _whitelistedAddresses) external onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        onlyWhitelistedAddressesCanCreateMarkets = true;
        for (uint256 index = 0; index < _whitelistedAddresses.length; index++) {
            whitelistedAddresses[_whitelistedAddresses[index]] = true;
        }
    }

    /// @notice setPositionalMarketFactory sets PositionalMarketFactory address
    /// @param _positionalMarketFactory address of PositionalMarketFactory
    function setPositionalMarketFactory(address _positionalMarketFactory) external onlyOwner {
        positionalMarketFactory = _positionalMarketFactory;
        emit SetPositionalMarketFactory(_positionalMarketFactory);
    }

    /// @notice setNeedsTransformingCollateral sets needsTransformingCollateral value
    /// @param _needsTransformingCollateral boolen value to be set
    function setNeedsTransformingCollateral(bool _needsTransformingCollateral) external onlyOwner {
        needsTransformingCollateral = _needsTransformingCollateral;
    }

    /// @notice setExpiryDuration sets expiryDuration value
    /// @param _expiryDuration value in seconds needed for market expiry check
    function setExpiryDuration(uint _expiryDuration) public onlyOwner {
        durations.expiryDuration = _expiryDuration;
        emit ExpiryDurationUpdated(_expiryDuration);
    }

    /// @notice setMaxTimeToMaturity sets maxTimeToMaturity value
    /// @param _maxTimeToMaturity value in seconds for market max time to maturity check
    function setMaxTimeToMaturity(uint _maxTimeToMaturity) public onlyOwner {
        durations.maxTimeToMaturity = _maxTimeToMaturity;
        emit MaxTimeToMaturityUpdated(_maxTimeToMaturity);
    }

    /// @notice setPriceFeed sets address of PriceFeed contract
    /// @param _address PriceFeed address
    function setPriceFeed(address _address) external onlyOwner {
        priceFeed = IPriceFeed(_address);
        emit SetPriceFeed(_address);
    }

    /// @notice setOnlyAMMMintingAndBurning whether minting and burning is only allowed for AMM
    /// @param _onlyAMMMintingAndBurning the value
    function setOnlyAMMMintingAndBurning(bool _onlyAMMMintingAndBurning) external onlyOwner {
        onlyAMMMintingAndBurning = _onlyAMMMintingAndBurning;
        emit SetOnlyAMMMintingAndBurning(_onlyAMMMintingAndBurning);
    }

    /// @notice setsUSD sets address of sUSD contract
    /// @param _address sUSD address
    function setsUSD(address _address) external onlyOwner {
        sUSD = IERC20(_address);
        emit SetsUSD(_address);
    }

    /// @notice setPriceBuffer sets priceBuffer value
    /// @param _priceBuffer value in percents needed for market creaton check
    function setPriceBuffer(uint _priceBuffer) external onlyOwner {
        priceBuffer = _priceBuffer;
        emit PriceBufferChanged(_priceBuffer);
    }

    /// @notice setTimeframeBuffer sets timeframeBuffer value
    /// @param _timeframeBuffer value in days needed for market creaton check
    function setTimeframeBuffer(uint _timeframeBuffer) external onlyOwner {
        timeframeBuffer = _timeframeBuffer;
        emit TimeframeBufferChanged(_timeframeBuffer);
    }

    /// @notice setMarketCreationEnabled sets marketCreationEnabled value
    /// @param enabled boolean value to enable/disable market creation
    function setMarketCreationEnabled(bool enabled) external onlyOwner {
        if (enabled != marketCreationEnabled) {
            marketCreationEnabled = enabled;
            emit MarketCreationEnabledUpdated(enabled);
        }
    }

    /// @notice _isValidKey checks if oracle key is supported by PriceFeed contract
    /// @param oracleKey oracle key
    /// @return bool
    function _isValidKey(bytes32 oracleKey) internal view returns (bool) {
        // If it has a rate, then it's possibly a valid key
        if (priceFeed.rateForCurrency(oracleKey) != 0) {
            return true;
        }

        return false;
    }

    /// @notice _checkStrikePrice checks if markets strike prices are between given price values
    /// @param markets list of markets to be checked
    /// @param strikePrice market strike price
    /// @param oracleKey market oracle key
    /// @return bool - true if there are no markets between given price values, otherwise false
    function _checkStrikePrice(
        address[] memory markets,
        uint strikePrice,
        bytes32 oracleKey
    ) internal view returns (bool) {
        uint buffer = (priceBuffer * _getImpliedVolatility(oracleKey)) / 1e18;
        for (uint i = 0; i < markets.length; i++) {
            uint upperPriceLimit = marketsStrikePrice[markets[i]] + (marketsStrikePrice[markets[i]] * buffer) / 1e20;
            uint lowerPriceLimit = marketsStrikePrice[markets[i]] - (marketsStrikePrice[markets[i]] * buffer) / 1e20;
            if (strikePrice <= upperPriceLimit && strikePrice >= lowerPriceLimit) {
                return false;
            }
        }
        return true;
    }

    /// @notice _checkMarkets checks if there exists similar market with same oracleKey
    /// @dev price limits are calculated from given strike price using priceBuffer percentage and
    /// we're checking lists of markets using timeframeBuffer
    /// @param oracleKey oracle key of the market to be created
    /// @param strikePrice strike price
    /// @param maturity market date maturity
    /// @return bool
    function _checkMarkets(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity
    ) internal view returns (bool) {
        uint date = _getDateFromTimestamp(maturity);

        for (uint day = 1; day <= timeframeBuffer; day++) {
            uint upperDateLimit = DateTime.addDays(date, day);
            uint lowerDateLimit = DateTime.subDays(date, day);

            address[] memory marketsDateAfter = _getMarketsPerOracleKey(oracleKey, upperDateLimit);
            address[] memory marketsDateBefore = _getMarketsPerOracleKey(oracleKey, lowerDateLimit);

            if (
                !(_checkStrikePrice(marketsDateAfter, strikePrice, oracleKey) &&
                    _checkStrikePrice(marketsDateBefore, strikePrice, oracleKey))
            ) {
                return false;
            }
        }

        address[] memory marketsOnDate = _getMarketsPerOracleKey(oracleKey, date);

        return _checkStrikePrice(marketsOnDate, strikePrice, oracleKey);
    }

    /// @notice _getMarketsPerOracleKey returns list of markets with same oracle key and maturity date
    /// @param oracleKey oracle key
    /// @param date maturity date
    /// @return address[] list of markets
    function _getMarketsPerOracleKey(bytes32 oracleKey, uint date) internal view returns (address[] memory) {
        return marketsPerOracleKey[oracleKey][date];
    }

    /// @notice _getDateFromTimestamp calculates midnight timestamp
    /// @param timestamp timestamp to strip seconds, minutes and hours
    /// @return date midnigth timestamp
    function _getDateFromTimestamp(uint timestamp) internal pure returns (uint date) {
        uint second = DateTime.getSecond(timestamp);
        uint minute = DateTime.getMinute(timestamp);
        uint hour = DateTime.getHour(timestamp);

        date = DateTime.subHours(timestamp, hour);
        date = DateTime.subMinutes(date, minute);
        date = DateTime.subSeconds(date, second);
    }

    /// @notice _getImpliedVolatility gets implied volatility per asset from ThalesAMM contract
    /// @param oracleKey asset to fetch value for
    /// @return impliedVolatility
    function _getImpliedVolatility(bytes32 oracleKey) internal view returns (uint impliedVolatility) {
        address thalesAMM = PositionalMarketFactory(positionalMarketFactory).thalesAMM();
        impliedVolatility = IThalesAMM(thalesAMM).impliedVolatilityPerAsset(oracleKey);
    }

    /// @notice get the thales amm address from the factory
    /// @return thales amm address
    function getThalesAMM() external view override returns (address) {
        return PositionalMarketFactory(positionalMarketFactory).thalesAMM();
    }

    /// @notice _transformCollateral transforms collateral if needed
    /// @param value value to be transformed
    /// @return uint
    function _transformCollateral(uint value) internal view returns (uint) {
        if (needsTransformingCollateral) {
            return value / 1e12;
        } else {
            return value;
        }
    }

    modifier onlyActiveMarkets() {
        require(_activeMarkets.contains(msg.sender), "Permitted only for active markets.");
        _;
    }

    modifier onlyKnownMarkets() {
        require(isKnownMarket(msg.sender), "Permitted only for known markets.");
        _;
    }

    event MarketCreated(
        address market,
        address indexed creator,
        bytes32 indexed oracleKey,
        uint strikePrice,
        uint maturityDate,
        uint expiryDate,
        address up,
        address down,
        bool customMarket,
        address customOracle
    );
    event MarketExpired(address market);
    event MarketsMigrated(PositionalMarketManager receivingManager, PositionalMarket[] markets);
    event MarketsReceived(PositionalMarketManager migratingManager, PositionalMarket[] markets);
    event MarketCreationEnabledUpdated(bool enabled);
    event ExpiryDurationUpdated(uint duration);
    event MaxTimeToMaturityUpdated(uint duration);
    event SetPositionalMarketFactory(address _positionalMarketFactory);
    event SetZeroExAddress(address _zeroExAddress);
    event SetPriceFeed(address _address);
    event SetsUSD(address _address);
    event SetMigratingManager(address manager);
    event PriceBufferChanged(uint priceBuffer);
    event TimeframeBufferChanged(uint timeframeBuffer);
    event SetOnlyAMMMintingAndBurning(bool _SetOnlyAMMMintingAndBurning);
}