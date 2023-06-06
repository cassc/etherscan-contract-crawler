// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imported contracts and libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// interfaces
import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IOptionToken} from "../interfaces/IOptionToken.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IMarginEngine} from "../interfaces/IMarginEngine.sol";

// libraries
import {BalanceUtil} from "../libraries/BalanceUtil.sol";
import {NumberUtil} from "../libraries/NumberUtil.sol";
import {ProductIdUtil} from "../libraries/ProductIdUtil.sol";
import {TokenIdUtil} from "../libraries/TokenIdUtil.sol";

// constants and types
import "../config/types.sol";
import "../config/enums.sol";
import "../config/constants.sol";
import "../config/errors.sol";

/**
 * @title   Pomace
 * @author  @dsshap, @antoncoding
 * @dev     This contract serves as the registry of the system who system.
 */
contract Pomace is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using BalanceUtil for Balance[];
    using FixedPointMathLib for uint256;
    using NumberUtil for uint256;
    using ProductIdUtil for uint32;
    using SafeCast for uint256;
    using TokenIdUtil for uint256;

    /// @dev optionToken address
    IOptionToken public immutable optionToken;

    /// @dev oracle address
    IOracle public immutable oracle;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev last id used to represent an address address
    uint8 public lastAssetId;

    /// @dev last id used to represent an engine address
    uint8 public lastEngineId;

    /// @dev assetId => asset address
    mapping(uint8 => AssetDetail) public assets;

    /// @dev engineId => margin engine address
    mapping(uint8 => address) public engines;

    /// @dev address => assetId
    mapping(address => uint8) public assetIds;

    /// @dev address => engineId
    mapping(address => uint8) public engineIds;

    /// @dev A bitmap of asset that are marginable
    ///      assetId => assetId masks
    mapping(uint256 => uint256) private collateralizable;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event OptionSettled(address account, uint256 tokenId, uint256 amountSettled, uint256 debt, uint256 payout);
    event AssetRegistered(address asset, uint8 id);
    event MarginEngineRegistered(address engine, uint8 id);
    event CollateralizableSet(address asset0, address asset1, bool value);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    /// @dev set immutables in constructor
    /// @dev also set the implementation contract to initialized = true
    constructor(address _optionToken, address _oracle) initializer {
        optionToken = IOptionToken(_optionToken);
        oracle = IOracle(_oracle);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();

        _transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  sets the Collateralizable Mask for a pair of assets
     * @param _asset0 the address of the asset 0
     * @param _asset1 the address of the asset 1
     * @param _value is margin-able
     */
    function setCollateralizable(address _asset0, address _asset1, bool _value) external {
        _checkOwner();

        uint256 collateralId = assetIds[_asset0];
        uint256 mask = 1 << assetIds[_asset1];

        if (_value) collateralizable[collateralId] |= mask;
        else collateralizable[collateralId] &= ~mask;

        emit CollateralizableSet(_asset0, _asset1, _value);
    }

    /**
     * @dev check if a pair of assets are collateralizable
     */
    function isCollateralizable(address _asset0, address _asset1) external view returns (bool) {
        return _isCollateralizable(assetIds[_asset0], assetIds[_asset1]);
    }

    /**
     * @dev check if a pair of assets are collateralizable
     */
    function isCollateralizable(uint8 _asset0, uint8 _asset1) external view returns (bool) {
        return _isCollateralizable(_asset0, _asset1);
    }

    /**
     * @dev parse product id into composing asset and engine addresses
     * @param _productId product id
     */
    function getDetailFromProductId(uint32 _productId)
        public
        view
        returns (
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        )
    {
        (uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId) = ProductIdUtil.parseProductId(_productId);
        AssetDetail memory underlyingDetail = assets[underlyingId];
        AssetDetail memory strikeDetail = assets[strikeId];
        AssetDetail memory collateralDetail = assets[collateralId];
        return (
            engines[engineId],
            underlyingDetail.addr,
            underlyingDetail.decimals,
            strikeDetail.addr,
            strikeDetail.decimals,
            collateralDetail.addr,
            collateralDetail.decimals
        );
    }

    /**
     * @dev parse token id into composing option details
     * @param _tokenId product id
     */
    function getDetailFromTokenId(uint256 _tokenId)
        external
        pure
        returns (TokenType tokenType, uint32 productId, uint64 expiry, uint64 strike, uint64 exerciseWindow)
    {
        return TokenIdUtil.parseTokenId(_tokenId);
    }

    /**
     * @notice    get product id from underlying, strike and collateral address
     * @dev       function will still return even if some of the assets are not registered
     * @param _underlying  underlying address
     * @param _strike      strike address
     * @param _collateral  collateral address
     */
    function getProductId(address _engine, address _underlying, address _strike, address _collateral)
        external
        view
        returns (uint32 id)
    {
        id = ProductIdUtil.getProductId(engineIds[_engine], assetIds[_underlying], assetIds[_strike], assetIds[_collateral]);
    }

    /**
     * @notice    get token id from type, productId, expiry, strike
     * @dev       function will still return even if some of the assets are not registered
     * @param _tokenType TokenType enum
     * @param _productId if of the product
     * @param _expiry timestamp of option expiry
     * @param _strike strike price of the long option, with 6 decimals
     * @param _exerciseWindow strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     */
    function getTokenId(TokenType _tokenType, uint32 _productId, uint256 _expiry, uint256 _strike, uint256 _exerciseWindow)
        external
        pure
        returns (uint256 id)
    {
        id = TokenIdUtil.getTokenId(_tokenType, _productId, uint64(_expiry), uint64(_strike), uint64(_exerciseWindow));
    }

    /**
     * @notice burn option token and get out cash value at expiry
     *
     * @param _account  who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount)
        public
        nonReentrant
        returns (Balance memory, Balance memory)
    {
        (address engine_, uint8 debtId, uint256 debt, uint8 payoutId, uint256 payout) =
            getDebtAndPayout(_tokenId, _amount.toUint64());

        emit OptionSettled(_account, _tokenId, _amount, debt, payout);

        optionToken.burnPomaceOnly(_account, _tokenId, _amount);

        if (debt > 0) {
            IMarginEngine engine = IMarginEngine(engine_);

            engine.handleExercise(_tokenId, debt, payout);
            // pull debt asset from msg.sender to engine
            engine.receiveDebtValue(assets[debtId].addr, msg.sender, debt);
            // make the engine pay out payout amount
            engine.sendPayoutValue(assets[payoutId].addr, _account, payout);
        }

        return (Balance(debtId, debt.toUint80()), Balance(payoutId, payout.toUint80()));
    }

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     *
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts) external nonReentrant {
        if (_tokenIds.length != _amounts.length) revert PM_WrongArgumentLength();

        if (_tokenIds.length == 0) return;

        optionToken.batchBurnPomaceOnly(_account, _tokenIds, _amounts);

        for (uint256 i; i < _tokenIds.length;) {
            settleOption(_account, _tokenIds[i], _amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev calculate the payout for option tokens
     *
     * @param _tokenId  token id of option token
     * @param _amount   amount to settle
     *
     * @return engine engine to settle
     * @return debtId asset id being pull from long holder
     * @return debt total pulled
     * @return payoutId asset id being sent to long holder
     * @return payout amount paid
     *
     */
    function getDebtAndPayout(uint256 _tokenId, uint64 _amount)
        public
        view
        returns (address engine, uint8 debtId, uint256 debt, uint8 payoutId, uint256 payout)
    {
        uint256 debtPerOption;
        uint256 payoutPerOption;

        (engine, debtId, debtPerOption, payoutId, payoutPerOption) = _getPayoutPerToken(_tokenId);
        debt = debtPerOption * _amount;
        payout = payoutPerOption * _amount;
        unchecked {
            debt = debt / UNIT;
            payout = payout / UNIT;
        }
    }

    /**
     * @dev calculate the payout for array of options
     *
     * @param _tokenIds array of token id
     * @param _amounts  array of amount
     *
     * @return debts amounts received
     * @return payouts amounts paid
     *
     */
    function batchGetDebtAndPayouts(uint256[] calldata _tokenIds, uint256[] calldata _amounts)
        external
        view
        returns (Balance[] memory debts, Balance[] memory payouts)
    {
        for (uint256 i; i < _tokenIds.length;) {
            (, uint8 debtId, uint256 debt, uint8 payoutId, uint256 payout) =
                getDebtAndPayout(_tokenIds[i], _amounts[i].toUint64());

            debts = _addToBalances(debts, debtId, debt);
            payouts = _addToBalances(payouts, payoutId, payout);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev revert if _engine doesn't have access to mint / burn a tokenId;
     * @param _tokenId tokenId
     * @param _engine address intending to mint / burn
     */
    function checkEngineAccess(uint256 _tokenId, address _engine) external view {
        // create check engine access
        uint8 engineId = TokenIdUtil.parseEngineId(_tokenId);
        if (_engine != engines[engineId]) revert PM_Not_Authorized_Engine();
    }

    /**
     * @dev revert if _engine doesn't have access to mint or the tokenId is invalid.
     * @param _tokenId tokenId
     * @param _engine address intending to mint / burn
     */
    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view {
        // check tokenId
        _isValidTokenIdToMint(_tokenId);

        //  check engine access
        uint8 engineId = _tokenId.parseEngineId();
        if (_engine != engines[engineId]) revert PM_Not_Authorized_Engine();
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev register an asset to be used as strike/underlying
     * @param _asset address to add
     * @return id asset ID
     */
    function registerAsset(address _asset) external returns (uint8 id) {
        _checkOwner();

        if (assetIds[_asset] != 0) revert PM_AssetAlreadyRegistered();

        uint8 decimals = IERC20Metadata(_asset).decimals();

        id = ++lastAssetId;
        assets[id] = AssetDetail({addr: _asset, decimals: decimals});
        assetIds[_asset] = id;

        emit AssetRegistered(_asset, id);
    }

    /**
     * @dev register an engine to create / settle options
     * @param _engine address of the new margin engine
     * @return id engine ID
     */
    function registerEngine(address _engine) external returns (uint8 id) {
        _checkOwner();

        if (engineIds[_engine] != 0) revert PM_EngineAlreadyRegistered();

        id = ++lastEngineId;
        engines[id] = _engine;

        engineIds[_engine] = id;

        emit MarginEngineRegistered(_engine, id);
    }

    /* =====================================
     *          Internal Functions
     * ====================================**/

    /**
     * @dev make sure that the tokenId make sense
     */
    function _isValidTokenIdToMint(uint256 _tokenId) internal view {
        (TokenType tokenType, uint32 productId, uint64 expiry,, uint64 exerciseWindow) = _tokenId.parseTokenId();

        // check settlement window
        if (exerciseWindow == 0) revert PM_InvalidExerciseWindow();

        (, uint8 underlyingId, uint8 strikeId, uint8 collateralId) = productId.parseProductId();

        if (tokenType == TokenType.CALL && underlyingId != collateralId && !_isCollateralizable(underlyingId, collateralId)) {
            revert PM_InvalidCollateral();
        }
        if (tokenType == TokenType.PUT && strikeId != collateralId && !_isCollateralizable(strikeId, collateralId)) {
            revert PM_InvalidCollateral();
        }

        // check expiry
        if (expiry <= block.timestamp) revert PM_InvalidExpiry();
    }

    /**
     * @dev calculate the payout for one option token
     *
     * @param _tokenId  token id of option token
     *
     * @return engine engine to settle
     * @return debtId asset id to be pulled from long holder
     * @return debtPerOption amount to be pulled per option
     * @return payoutId asset id to be payed out to long holder
     * @return payoutPerOption amount paid per option
     *
     */
    function _getPayoutPerToken(uint256 _tokenId)
        internal
        view
        returns (address engine, uint8 debtId, uint256 debtPerOption, uint8 payoutId, uint256 payoutPerOption)
    {
        (TokenType tokenType, uint32 productId, uint64 expiry, uint64 strikePrice, uint64 exerciseWindow) =
            TokenIdUtil.parseTokenId(_tokenId);

        if (block.timestamp < expiry) revert PM_NotExpired();

        if (block.timestamp > expiry + exerciseWindow) return (address(0), 0, 0, 0, 0);

        (uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId) = productId.parseProductId();

        engine = engines[engineId];

        uint256 underlyingValue;
        uint256 strikeValue;

        // calculate value of collateral if not underlying or strike
        if (tokenType == TokenType.CALL && collateralId != underlyingId) {
            if (!_isCollateralizable(underlyingId, collateralId)) revert PM_InvalidCollateral();

            AssetDetail memory collateralDetail = assets[collateralId];

            uint256 collateralPrice = _getSettlementPrice(collateralDetail.addr, assets[underlyingId].addr, expiry);
            underlyingValue = UNIT.mulDivDown(UNIT, collateralPrice);

            underlyingValue = underlyingValue.convertDecimals(UNIT_DECIMALS, collateralDetail.decimals);
        } else if (tokenType == TokenType.PUT && collateralId != strikeId) {
            if (!_isCollateralizable(strikeId, collateralId)) revert PM_InvalidCollateral();

            AssetDetail memory collateralDetail = assets[collateralId];

            uint256 collateralPrice = _getSettlementPrice(collateralDetail.addr, assets[strikeId].addr, expiry);
            strikeValue = uint256(strikePrice).mulDivDown(UNIT, collateralPrice);

            strikeValue = strikeValue.convertDecimals(UNIT_DECIMALS, collateralDetail.decimals);
        }

        // setting default values if not set in above section
        if (underlyingValue == 0) underlyingValue = UNIT.convertDecimals(UNIT_DECIMALS, assets[underlyingId].decimals);
        if (strikeValue == 0) strikeValue = uint256(strikePrice).convertDecimals(UNIT_DECIMALS, assets[strikeId].decimals);

        payoutId = collateralId;
        if (tokenType == TokenType.CALL) {
            debtId = strikeId;
            debtPerOption = strikeValue;

            payoutPerOption = underlyingValue;
        } else if (tokenType == TokenType.PUT) {
            debtId = underlyingId;
            debtPerOption = underlyingValue;

            payoutPerOption = strikeValue;
        }
    }

    /**
     * @dev add an entry to array of Balance
     * @param payouts existing payout array
     * @param collateralId new collateralId
     * @param payout new payout
     */
    function _addToBalances(Balance[] memory payouts, uint8 collateralId, uint256 payout)
        internal
        pure
        returns (Balance[] memory)
    {
        if (payout == 0) return payouts;

        (bool found, uint256 index) = payouts.indexOf(collateralId);
        if (!found) {
            payouts = payouts.append(Balance(collateralId, payout.toUint80()));
        } else {
            payouts[index].amount += payout.toUint80();
        }

        return payouts;
    }

    /**
     * @dev check if a pair of assetIds are collateralizable
     */
    function _isCollateralizable(uint8 _assetId0, uint8 _assetId1) internal view returns (bool) {
        if (_assetId0 == _assetId1) return true;

        uint256 mask = 1 << _assetId1;
        return collateralizable[_assetId0] & mask != 0;
    }

    /**
     * @dev check settlement price is finalized from oracle, and return price
     * @param _base base asset (ETH is base asset while requesting ETH / USD)
     * @param _quote quote asset (USD is quote asset while requesting ETH / USD)
     * @param _expiry expiry timestamp
     */
    function _getSettlementPrice(address _base, address _quote, uint256 _expiry) internal view returns (uint256) {
        (uint256 price, bool isFinalized) = oracle.getPriceAtExpiry(_base, _quote, _expiry);
        if (!isFinalized) revert PM_PriceNotFinalized();
        return price;
    }
}