//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {StorageSlot as StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {DataTypes} from "@yield-protocol/vault-v2/contracts/interfaces/DataTypes.sol";
import {IContangoLadle} from "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoLadle.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";

import {MarketParameters, Token, TokenType} from "../liquiditysource/notional/internal/Types.sol";
import {NotionalProxy} from "../liquiditysource/notional/internal/interfaces/NotionalProxy.sol";
import {ContangoVault} from "../liquiditysource/notional/ContangoVault.sol";
import {NotionalUtils} from "../liquiditysource/notional/NotionalUtils.sol";

import {IFeeModel} from "../interfaces/IFeeModel.sol";
import {ERC20Lib} from "./ERC20Lib.sol";
import "./ErrorLib.sol";
import "./DataTypes.sol";
import "../ContangoPositionNFT.sol";

// solhint-disable no-inline-assembly
library StorageLib {
    event UniswapFeeUpdated(Symbol indexed symbol, uint24 uniswapFee);
    event FeeModelUpdated(Symbol indexed symbol, IFeeModel feeModel);

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots available
    /// Make sure it's different from any other StorageLib
    uint256 private constant STORAGE_SLOT_BASE = 1_000_000;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum StorageId {
        Unused, // 0
        PositionBalances, // 1
        PositionNotionals, // 2
        InstrumentFeeModel, // 3
        PositionInstrument, // 4
        Instrument // 5
    }

    /// @dev Mapping from a position id to encoded position balances
    function getPositionBalances() internal pure returns (mapping(PositionId => uint256) storage store) {
        return _getUint256ToUint256Mapping(StorageId.PositionBalances);
    }

    /// @dev Mapping from a position id to encoded position notionals
    function getPositionNotionals() internal pure returns (mapping(PositionId => uint256) storage store) {
        return _getUint256ToUint256Mapping(StorageId.PositionNotionals);
    }

    /// @dev Mapping from an instrument symbol to a fee model
    function getInstrumentFeeModel() internal pure returns (mapping(Symbol => IFeeModel) storage store) {
        uint256 slot = getStorageSlot(StorageId.InstrumentFeeModel);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Mapping from a position id to a fee model
    function getInstrumentFeeModel(PositionId positionId) internal view returns (IFeeModel) {
        return getInstrumentFeeModel()[getPositionInstrument()[positionId]];
    }

    /// @dev Mapping from a position id to an instrument symbol
    function getPositionInstrument() internal pure returns (mapping(PositionId => Symbol) storage store) {
        uint256 slot = getStorageSlot(StorageId.PositionInstrument);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Mapping from an instrument symbol to an instrument
    function getInstruments() internal pure returns (mapping(Symbol => Instrument) storage store) {
        uint256 slot = getStorageSlot(StorageId.Instrument);
        assembly {
            store.slot := slot
        }
    }

    function getInstrument(PositionId positionId)
        internal
        view
        returns (Symbol symbol, Instrument storage instrument)
    {
        symbol = StorageLib.getPositionInstrument()[positionId];
        instrument = getInstruments()[symbol];
    }

    function setFeeModel(Symbol symbol, IFeeModel feeModel) internal {
        StorageLib.getInstrumentFeeModel()[symbol] = feeModel;
        emit FeeModelUpdated(symbol, feeModel);
    }

    function setInstrumentUniswapFee(Symbol symbol, uint24 uniswapFee) internal {
        Instrument storage instrument = StorageLib.getInstruments()[symbol];
        if (instrument.uniswapFee == 0) {
            revert InvalidInstrument(symbol);
        }
        instrument.uniswapFee = uniswapFee;
        emit UniswapFeeUpdated(symbol, uniswapFee);
    }

    function _getUint256ToUint256Mapping(StorageId storageId)
        private
        pure
        returns (mapping(PositionId => uint256) storage store)
    {
        uint256 slot = getStorageSlot(storageId);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

library YieldStorageLib {
    using SafeCast for uint256;

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots available
    /// Make sure it's different from any other StorageLib
    uint256 private constant YIELD_STORAGE_SLOT_BASE = 2_000_000;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum YieldStorageId {
        Unused, // 0
        Instruments, // 1
        Joins, // 2
        Ladle, // 3
        Cauldron, // 4
        PoolView // 5
    }

    error InvalidBaseId(Symbol symbol, bytes6 baseId);
    error InvalidQuoteId(Symbol symbol, bytes6 quoteId);
    error MismatchedMaturity(Symbol symbol, bytes6 baseId, uint256 baseMaturity, bytes6 quoteId, uint256 quoteMaturity);

    event YieldInstrumentCreated(Instrument instrument, YieldInstrument yieldInstrument);
    event LadleSet(IContangoLadle ladle);
    event CauldronSet(ICauldron cauldron);

    function getLadle() internal view returns (IContangoLadle) {
        return IContangoLadle(StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Ladle))).value);
    }

    function setLadle(IContangoLadle ladle) internal {
        StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Ladle))).value = address(ladle);
        emit LadleSet(ladle);
    }

    function getCauldron() internal view returns (ICauldron) {
        return ICauldron(StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Cauldron))).value);
    }

    function setCauldron(ICauldron cauldron) internal {
        StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Cauldron))).value = address(cauldron);
        emit CauldronSet(cauldron);
    }

    /// @dev Mapping from a symbol to instrument
    function getInstruments() internal pure returns (mapping(Symbol => YieldInstrument) storage store) {
        uint256 slot = getStorageSlot(YieldStorageId.Instruments);
        assembly {
            store.slot := slot
        }
    }

    function createInstrument(Symbol symbol, bytes6 baseId, bytes6 quoteId, uint24 uniswapFee, IFeeModel feeModel)
        internal
        returns (Instrument memory instrument, YieldInstrument memory yieldInstrument)
    {
        ICauldron cauldron = getCauldron();
        (DataTypes.Series memory baseSeries, DataTypes.Series memory quoteSeries) =
            _validInstrumentData(cauldron, symbol, baseId, quoteId);

        StorageLib.getInstrumentFeeModel()[symbol] = feeModel;
        IContangoLadle ladle = getLadle();

        (instrument, yieldInstrument) =
            _createInstrument(ladle, cauldron, baseId, quoteId, uniswapFee, baseSeries, quoteSeries);

        getJoins()[yieldInstrument.baseId] = address(ladle.joins(yieldInstrument.baseId));
        getJoins()[yieldInstrument.quoteId] = address(ladle.joins(yieldInstrument.quoteId));

        StorageLib.getInstruments()[symbol] = instrument;
        getInstruments()[symbol] = yieldInstrument;

        emit YieldInstrumentCreated(instrument, yieldInstrument);
    }

    function _createInstrument(
        IContangoLadle ladle,
        ICauldron cauldron,
        bytes6 baseId,
        bytes6 quoteId,
        uint24 uniswapFee,
        DataTypes.Series memory baseSeries,
        DataTypes.Series memory quoteSeries
    ) private view returns (Instrument memory instrument, YieldInstrument memory yieldInstrument) {
        yieldInstrument.baseId = baseId;
        yieldInstrument.quoteId = quoteId;

        yieldInstrument.basePool = IPool(ladle.pools(yieldInstrument.baseId));
        yieldInstrument.quotePool = IPool(ladle.pools(yieldInstrument.quoteId));

        yieldInstrument.baseFyToken = baseSeries.fyToken;
        yieldInstrument.quoteFyToken = quoteSeries.fyToken;

        DataTypes.Debt memory debt = cauldron.debt(quoteSeries.baseId, yieldInstrument.baseId);
        yieldInstrument.minQuoteDebt = debt.min * uint96(10) ** debt.dec;

        instrument.maturity = baseSeries.maturity;
        instrument.uniswapFee = uniswapFee;
        instrument.base = IERC20Metadata(yieldInstrument.baseFyToken.underlying());
        instrument.quote = IERC20Metadata(yieldInstrument.quoteFyToken.underlying());
    }

    function getJoins() internal pure returns (mapping(bytes12 => address) storage store) {
        uint256 slot = getStorageSlot(YieldStorageId.Joins);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `YieldStorageId`
    /// @return slot The storage slot.
    function getStorageSlot(YieldStorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + YIELD_STORAGE_SLOT_BASE;
    }

    function _validInstrumentData(ICauldron cauldron, Symbol symbol, bytes6 baseId, bytes6 quoteId)
        private
        view
        returns (DataTypes.Series memory baseSeries, DataTypes.Series memory quoteSeries)
    {
        if (StorageLib.getInstruments()[symbol].maturity != 0) {
            revert InstrumentAlreadyExists(symbol);
        }

        baseSeries = cauldron.series(baseId);
        uint256 baseMaturity = baseSeries.maturity;
        if (baseMaturity == 0 || baseMaturity > type(uint32).max) {
            revert InvalidBaseId(symbol, baseId);
        }

        quoteSeries = cauldron.series(quoteId);
        uint256 quoteMaturity = quoteSeries.maturity;
        if (quoteMaturity == 0 || quoteMaturity > type(uint32).max) {
            revert InvalidQuoteId(symbol, quoteId);
        }

        if (baseMaturity != quoteMaturity) {
            revert MismatchedMaturity(symbol, baseId, baseMaturity, quoteId, quoteMaturity);
        }
    }
}

library NotionalStorageLib {
    using ERC20Lib for IERC20;
    using NotionalUtils for IERC20Metadata;
    using SafeCast for uint256;

    NotionalProxy internal constant NOTIONAL = NotionalProxy(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots available
    /// Make sure it's different from any other StorageLib
    uint256 private constant NOTIONAL_STORAGE_SLOT_BASE = 3_000_000;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum NotionalStorageId {
        Unused, // 0
        Instruments, // 1
        Vaults // 2
    }

    error InvalidBaseId(Symbol symbol, uint16 currencyId);
    error InvalidQuoteId(Symbol symbol, uint16 currencyId);
    error InvalidMarketIndex(uint16 currencyId, uint256 marketIndex, uint256 max);
    error MismatchedMaturity(Symbol symbol, uint16 baseId, uint32 baseMaturity, uint16 quoteId, uint32 quoteMaturity);

    event NotionalInstrumentCreated(Instrument instrument, NotionalInstrument notionalInstrument, ContangoVault vault);

    function getVaults() internal pure returns (mapping(Symbol => ContangoVault) storage store) {
        uint256 slot = getStorageSlot(NotionalStorageId.Vaults);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Mapping from a symbol to instrument
    function getInstruments() internal pure returns (mapping(Symbol => NotionalInstrument) storage store) {
        uint256 slot = getStorageSlot(NotionalStorageId.Instruments);
        assembly {
            store.slot := slot
        }
    }

    function getInstrument(PositionId positionId) internal view returns (NotionalInstrument storage) {
        return getInstruments()[StorageLib.getPositionInstrument()[positionId]];
    }

    function createInstrument(
        Symbol symbol,
        uint16 baseId,
        uint16 quoteId,
        uint256 marketIndex,
        uint24 uniswapFee,
        IFeeModel feeModel,
        ContangoVault vault,
        address weth // sucks but beats doing another SLOAD to fetch from configs
    ) internal returns (Instrument memory instrument, NotionalInstrument memory notionalInstrument) {
        StorageLib.getInstrumentFeeModel()[symbol] = feeModel;

        uint32 maturity = _validInstrumentData(symbol, baseId, quoteId, marketIndex);
        (instrument, notionalInstrument) = _createInstrument(baseId, quoteId, maturity, uniswapFee, weth);

        // since the contango contracts should not hold any funds once a transaction is done,
        // and createInstrument is a permissioned manually invoked admin function (therefore with controlled inputs),
        // infinite approve here to the vault is fine
        IERC20(instrument.base).checkedInfiniteApprove(address(vault));
        IERC20(instrument.quote).checkedInfiniteApprove(address(vault));

        StorageLib.getInstruments()[symbol] = instrument;
        getInstruments()[symbol] = notionalInstrument;
        getVaults()[symbol] = vault;

        emit NotionalInstrumentCreated(instrument, notionalInstrument, vault);
    }

    function _createInstrument(uint16 baseId, uint16 quoteId, uint32 maturity, uint24 uniswapFee, address weth)
        private
        view
        returns (Instrument memory instrument, NotionalInstrument memory notionalInstrument)
    {
        notionalInstrument.baseId = baseId;
        notionalInstrument.quoteId = quoteId;

        instrument.maturity = maturity;
        instrument.uniswapFee = uniswapFee;

        (, Token memory baseUnderlyingToken) = NOTIONAL.getCurrency(baseId);
        (, Token memory quoteUnderlyingToken) = NOTIONAL.getCurrency(quoteId);

        address baseAddress = baseUnderlyingToken.tokenType == TokenType.Ether ? weth : baseUnderlyingToken.tokenAddress;
        address quoteAddress =
            quoteUnderlyingToken.tokenType == TokenType.Ether ? weth : quoteUnderlyingToken.tokenAddress;

        instrument.base = IERC20Metadata(baseAddress);
        instrument.quote = IERC20Metadata(quoteAddress);

        notionalInstrument.basePrecision = (10 ** instrument.base.decimals()).toUint64();
        notionalInstrument.quotePrecision = (10 ** instrument.quote.decimals()).toUint64();

        notionalInstrument.isQuoteWeth = address(instrument.quote) == address(weth);
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `NotionalStorageId`
    /// @return slot The storage slot.
    function getStorageSlot(NotionalStorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + NOTIONAL_STORAGE_SLOT_BASE;
    }

    function _validInstrumentData(Symbol symbol, uint16 baseId, uint16 quoteId, uint256 marketIndex)
        private
        view
        returns (uint32)
    {
        if (StorageLib.getInstruments()[symbol].maturity != 0) {
            revert InstrumentAlreadyExists(symbol);
        }

        // should never happen in Notional since it validates that the currencyId is valid and has a valid maturity
        uint256 baseMaturity = _validateMarket(NOTIONAL, baseId, marketIndex);
        if (baseMaturity == 0 || baseMaturity > type(uint32).max) {
            revert InvalidBaseId(symbol, baseId);
        }

        // should never happen in Notional since it validates that the currencyId is valid and has a valid maturity
        uint256 quoteMaturity = _validateMarket(NOTIONAL, quoteId, marketIndex);
        if (quoteMaturity == 0 || quoteMaturity > type(uint32).max) {
            revert InvalidQuoteId(symbol, quoteId);
        }

        // should never happen since we're using the exact marketIndex on the same block/timestamp
        if (baseMaturity != quoteMaturity) {
            revert MismatchedMaturity(symbol, baseId, uint32(baseMaturity), quoteId, uint32(quoteMaturity));
        }

        return uint32(baseMaturity);
    }

    function _validateMarket(NotionalProxy notional, uint16 currencyId, uint256 marketIndex)
        private
        view
        returns (uint256 maturity)
    {
        MarketParameters[] memory marketParameters = notional.getActiveMarkets(currencyId);
        if (marketIndex == 0 || marketIndex > marketParameters.length) {
            revert InvalidMarketIndex(currencyId, marketIndex, marketParameters.length);
        }

        maturity = marketParameters[marketIndex - 1].maturity;
    }
}

library ConfigStorageLib {
    bytes32 private constant TREASURY = keccak256("ConfigStorageLib.TREASURY");
    bytes32 private constant NFT = keccak256("ConfigStorageLib.NFT");
    bytes32 private constant CLOSING_ONLY = keccak256("ConfigStorageLib.CLOSING_ONLY");
    bytes32 private constant TRUSTED_TOKENS = keccak256("ConfigStorageLib.TRUSTED_TOKENS");
    bytes32 private constant PROXY_HASH = keccak256("ConfigStorageLib.PROXY_HASH");

    event TreasurySet(address treasury);
    event PositionNFTSet(address positionNFT);
    event ClosingOnlySet(bool closingOnly);
    event TokenTrusted(address indexed token, bool trusted);
    event ProxyHashSet(bytes32 proxyHash);

    function getTreasury() internal view returns (address) {
        return StorageSlot.getAddressSlot(TREASURY).value;
    }

    function setTreasury(address treasury) internal {
        StorageSlot.getAddressSlot(TREASURY).value = treasury;
        emit TreasurySet(address(treasury));
    }

    function getPositionNFT() internal view returns (ContangoPositionNFT) {
        return ContangoPositionNFT(StorageSlot.getAddressSlot(NFT).value);
    }

    function setPositionNFT(ContangoPositionNFT nft) internal {
        StorageSlot.getAddressSlot(NFT).value = address(nft);
        emit PositionNFTSet(address(nft));
    }

    function getClosingOnly() internal view returns (bool) {
        return StorageSlot.getBooleanSlot(CLOSING_ONLY).value;
    }

    function setClosingOnly(bool closingOnly) internal {
        StorageSlot.getBooleanSlot(CLOSING_ONLY).value = closingOnly;
        emit ClosingOnlySet(closingOnly);
    }

    function isTrustedToken(address token) internal view returns (bool) {
        return _getAddressToBoolMapping(TRUSTED_TOKENS)[token];
    }

    function setTrustedToken(address token, bool trusted) internal {
        _getAddressToBoolMapping(TRUSTED_TOKENS)[token] = trusted;
        emit TokenTrusted(token, trusted);
    }

    function getProxyHash() internal view returns (bytes32) {
        return StorageSlot.getBytes32Slot(PROXY_HASH).value;
    }

    function setProxyHash(bytes32 proxyHash) internal {
        StorageSlot.getBytes32Slot(PROXY_HASH).value = proxyHash;
        emit ProxyHashSet(proxyHash);
    }

    function _getAddressToBoolMapping(bytes32 slot) private pure returns (mapping(address => bool) storage store) {
        assembly {
            store.slot := slot
        }
    }
}