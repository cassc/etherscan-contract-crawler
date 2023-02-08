// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ReservoirOracle} from "@reservoir/ReservoirOracle.sol";

contract ReservoirOracleUnderwriter {
    /// @notice The kind of floor price to use from the oracle
    /// @dev SPOT is the floor price at the time of the oracle message
    /// @dev TWAP is the average weighted floor price over the last TWAP_SECONDS
    /// @dev LOWER is the minimum of SPOT and TWAP
    /// @dev UPPER is the maximum of SPOT and TWAP
    /// @dev see https://docs.reservoir.tools/reference/getoraclecollectionstopbidv2 for more details
    enum PriceKind {
        SPOT,
        TWAP,
        LOWER,
        UPPER
    }

    /// @notice The signature of a message from our oracle signer
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice The message and signature from our oracle signer
    struct OracleInfo {
        ReservoirOracle.Message message;
        Sig sig;
    }

    /// @notice Describes a cached oracle price for a given NFT collection
    /// @dev used to constrain how quickly price can grow and guard against oracle attacks
    struct CachedPrice {
        // the timestamp the price was cached
        uint40 timestamp;
        // the oracle price of the NFT collection
        uint216 price;
    }

    error IncorrectOracleSigner();
    error WrongIdentifierFromOracleMessage();
    error WrongCurrencyFromOracleMessage();
    error OracleMessageTimestampInvalid();

    /// @notice the amount of time to use for the TWAP
    uint256 constant TWAP_SECONDS = 7 days;

    /// @notice the maximum time a given signed oracle message is valid for
    uint256 constant VALID_FOR = 20 minutes;

    /// @dev constant values used in checking signatures
    bytes32 constant MESSAGE_SIG_HASH = keccak256("Message(bytes32 id,bytes payload,uint256 timestamp)");
    bytes32 constant TOP_BID_SIG_HASH =
        keccak256("ContractWideCollectionTopBidPrice(uint8 kind,uint256 twapSeconds,address contract)");

    /// @notice The max per second price appreciation allowed for any collateral asset
    /// @dev used to guard against oracle attacks
    uint256 public constant MAX_PER_SECOND_PRICE_GROWTH = 0.5e18 / uint256(1 days);

    /// @notice the signing address the contract expects from the oracle message
    address public immutable oracleSigner;

    /// @notice address of the currency we are receiving oracle prices in
    address public immutable quoteCurrency;

    /// @notice returns the cached timestamp and price for asset
    mapping(ERC721 => CachedPrice) public cachedPriceForAsset;

    constructor(address _oracleSigner, address _quoteCurrency) {
        oracleSigner = _oracleSigner;
        quoteCurrency = _quoteCurrency;
    }

    /// @notice returns the price of an asset from a signed oracle message
    /// @dev reverts if the signer of the oracle message is incorrect
    /// @dev reverts if the oracle message was signed longer than VALID_FOR ago
    /// @dev reverts if the oracle message is for the wrong ERC721 asset, wrong price kind, or wrong quote currency
    /// @param asset the address of the ERC721 asset to underwrite the price for
    /// @param priceKind the kind of price the function expects the oracle message to contain
    /// @param oracleInfo the message and signature from our oracle signer
    /// @param guard whether to use a guard to constrain price appreciation
    /// @return oraclePrice the price of the asset, expressed in quoteCurrency units. Price is max allowed price given 
    ///         MAX_PER_SECOND_PRICE_GROWTH if guard = true and oracleInfo price > max
    function underwritePriceForCollateral(ERC721 asset, PriceKind priceKind, OracleInfo memory oracleInfo, bool guard)
        public
        returns (uint256)
    {
        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            MESSAGE_SIG_HASH,
                            oracleInfo.message.id,
                            keccak256(oracleInfo.message.payload),
                            oracleInfo.message.timestamp
                        )
                    )
                )
            ),
            oracleInfo.sig.v,
            oracleInfo.sig.r,
            oracleInfo.sig.s
        );

        if (signerAddress != oracleSigner) {
            revert IncorrectOracleSigner();
        }

        bytes32 expectedId = keccak256(abi.encode(TOP_BID_SIG_HASH, priceKind, TWAP_SECONDS, asset));

        if (oracleInfo.message.id != expectedId) {
            revert WrongIdentifierFromOracleMessage();
        }

        if (
            oracleInfo.message.timestamp > block.timestamp || oracleInfo.message.timestamp + VALID_FOR < block.timestamp
        ) {
            revert OracleMessageTimestampInvalid();
        }

        (address oracleQuoteCurrency, uint256 oraclePrice) = abi.decode(oracleInfo.message.payload, (address, uint256));
        if (oracleQuoteCurrency != quoteCurrency) {
            revert WrongCurrencyFromOracleMessage();
        }

        return guard ? _cacheAndReturnPriceOrMaxPrice(asset, oraclePrice) : oraclePrice;
    }

    /// @notice caches and returns the minimum of the passed price and the max price as well as the timestamp
    /// @dev max price computed by MAX_PER_SECOND_PRICE_GROWTH * time elapsed since the cache was last updated
    /// @dev time elapsed maxes at 2 days such that price can never grow by more than 100% between two successive
    ///      increase debt events for the same asset
    function _cacheAndReturnPriceOrMaxPrice(ERC721 asset, uint256 price) internal returns (uint256) {
        CachedPrice memory cached = cachedPriceForAsset[asset];
        if (cached.price != 0 && cached.price < price) {
            uint256 timeElapsed = block.timestamp - cached.timestamp;
            if (timeElapsed > 2 days) {
                timeElapsed = 2 days;
            }
            uint256 max = FixedPointMathLib.mulWadDown(
                cached.price, (MAX_PER_SECOND_PRICE_GROWTH * timeElapsed) + FixedPointMathLib.WAD
            );
            if (price > max) {
                price = max;
            }
        }

        // We are OK with not checking for price overflow when casting to uint216
        // as we do not consider values greater than this to be a practical possibility
        cachedPriceForAsset[asset] = CachedPrice({timestamp: uint40(block.timestamp), price: uint216(price)});

        return price;
    }
}