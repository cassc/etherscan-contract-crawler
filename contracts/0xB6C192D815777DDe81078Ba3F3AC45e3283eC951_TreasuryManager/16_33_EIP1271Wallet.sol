// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;
pragma abicoder v2;

import "ERC20.sol";
import "ECDSA.sol";
import {WETH9} from "WETH9.sol";
import {AggregatorV2V3Interface} from "AggregatorV2V3Interface.sol";

contract EIP1271Wallet {
    // 0x order encoding is implemented in _encodeEIP1271OrderWithHash
    // https://github.com/0xProject/0x-monorepo/blob/development/contracts/exchange/contracts/src/MixinSignatureValidator.sol
    uint256 internal constant ORDER_HASH_OFFSET = 36;
    uint256 internal constant TAKER_ADDRESS_OFFSET = 100;
    uint256 internal constant FEE_RECIPIENT_OFFSET = 144;
    uint256 internal constant SENDER_ADDRESS_OFFSET = 176;
    uint256 internal constant MAKER_AMOUNT_OFFSET = 196;
    uint256 internal constant TAKER_AMOUNT_OFFSET = 228;
    uint256 internal constant MAKER_FEE_AMOUNT_OFFSET = 260;
    uint256 internal constant TAKER_FEE_AMOUNT_OFFSET = 292;
    uint256 internal constant MAKER_TOKEN_OFFSET = 564;
    uint256 internal constant TAKER_TOKEN_OFFSET = 660;
    uint256 internal constant SLIPPAGE_LIMIT_PRECISION = 1e8;

    bytes4 internal constant EIP1271_MAGIC_NUM = 0x20c13b0b;
    bytes4 internal constant EIP1271_INVALID_SIG = 0xffffffff;
    WETH9 public immutable WETH;
    mapping(address => address) public priceOracles;
    mapping(address => uint256) public slippageLimits;

    event PriceOracleUpdated(address tokenAddress, address oracleAddress);
    event SlippageLimitUpdated(address tokenAddress, uint256 slippageLimit);

    constructor(WETH9 _weth) {
        WETH = _weth;
    }

    function _toAddress(bytes memory _bytes, uint256 _start)
        private
        pure
        returns (address)
    {
        // _bytes.length checked by the caller
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function _toUint256(bytes memory _bytes, uint256 _start)
        private
        pure
        returns (uint256)
    {
        // _bytes.length checked by the caller
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function _toBytes32(bytes memory _bytes, uint256 _start)
        private
        pure
        returns (bytes32)
    {
        // _bytes.length checked by the caller
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function _toUint(int256 x) private pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    /// @notice extracts order information from the encoded 0x order object
    function _extractOrderInfo(bytes memory encoded)
        private
        pure
        returns (
            address takerAddress,
            address makerToken,
            address takerToken,
            address feeRecipient,
            address senderAddress,
            uint256 makerAmount,
            uint256 takerAmount,
            uint256 makerFeeAmount,
            uint256 takerFeeAmount
        )
    {
        require(
            encoded.length >= TAKER_TOKEN_OFFSET + 32,
            "encoded: invalid length"
        );
        takerAddress = _toAddress(encoded, TAKER_ADDRESS_OFFSET);
        feeRecipient = _toAddress(encoded, FEE_RECIPIENT_OFFSET);
        senderAddress = _toAddress(encoded, SENDER_ADDRESS_OFFSET);
        makerAmount = _toUint256(encoded, MAKER_AMOUNT_OFFSET);
        takerAmount = _toUint256(encoded, TAKER_AMOUNT_OFFSET);
        makerFeeAmount = _toUint256(encoded, MAKER_FEE_AMOUNT_OFFSET);
        takerFeeAmount = _toUint256(encoded, TAKER_FEE_AMOUNT_OFFSET);
        makerToken = _toAddress(encoded, MAKER_TOKEN_OFFSET);
        takerToken = _toAddress(encoded, TAKER_TOKEN_OFFSET);
    }

    /// @notice extracts the order hash from the encoded 0x order object
    function _extractOrderHash(bytes memory encoded)
        private
        pure
        returns (bytes32)
    {
        require(
            encoded.length >= ORDER_HASH_OFFSET + 32,
            "encoded: invalid length"
        );

        return _toBytes32(encoded, ORDER_HASH_OFFSET);
    }

    /// @notice sets the price oracle for a given token
    function _setPriceOracle(address tokenAddress, address oracleAddress)
        internal
    {
        require(oracleAddress != address(0), "invalid oracle address");
        priceOracles[tokenAddress] = oracleAddress;
        emit PriceOracleUpdated(tokenAddress, oracleAddress);
    }

    /// @notice slippage limit sets the price floor of the maker token based on the oracle price
    /// SLIPPAGE_LIMIT_PRECISION = 1e8 = 100% of the current oracle price
    function _setSlippageLimit(address tokenAddress, uint256 slippageLimit)
        internal
    {
        require(
            slippageLimit <= SLIPPAGE_LIMIT_PRECISION,
            "invalid slippage limit"
        );
        slippageLimits[tokenAddress] = slippageLimit;
        emit SlippageLimitUpdated(tokenAddress, slippageLimit);
    }

    /// @notice make sure the order satisfies some pre-defined constraints
    function _validateOrder(bytes memory order) private view {
        (
            address takerAddress,
            address makerToken,
            address takerToken,
            address feeRecipient,
            address senderAddress,
            uint256 makerAmount,
            uint256 takerAmount,
            uint256 makerFeeAmount,
            uint256 takerFeeAmount
        ) = _extractOrderInfo(order);

        // Make sure anyone can fill these orders
        require(takerAddress == address(0), "manager cannot set taker");
        require(senderAddress == address(0), "manager cannot set sender");

        // No fee recipient allowed
        require(feeRecipient == address(0), "no fee recipient allowed");

        // MakerToken should never be WETH
        require(makerToken != address(WETH), "maker token must not be WETH");

        // TakerToken (proceeds) should always be WETH
        require(takerToken == address(WETH), "taker token must be WETH");

        // No fees allowed
        require(makerFeeAmount == 0, "maker fee must be 0");
        require(takerFeeAmount == 0, "taker fee must be 0");

        address priceOracle = priceOracles[makerToken];

        // Price oracle not defined
        require(priceOracle != address(0), "price oracle not defined");

        uint256 slippageLimit = slippageLimits[makerToken];

        // Slippage limit not defined
        require(slippageLimit != 0, "slippage limit not defined");

        // prettier-ignore
        (
            /* roundId */,
            int256 rate,
            /* uint256 startedAt */,
            /* updatedAt */,
            /* answeredInRound */
        ) = AggregatorV2V3Interface(priceOracle).latestRoundData();
        require(rate > 0, "Invalid rate");

        uint256 rateDecimals = AggregatorV2V3Interface(priceOracle).decimals();
        require(rateDecimals <= 18, "Invalid rate precision");

        /// @dev no overflow because rate is always > 0
        uint256 priceFloor = (uint256(rate) * slippageLimit) /
            SLIPPAGE_LIMIT_PRECISION;

        // make sure priceFloor is always 18 decimals
        priceFloor *= 10**(18 - rateDecimals);

        uint256 makerDecimals = 10**ERC20(makerToken).decimals();

        // makerPrice = takerAmount / makerAmount
        uint256 makerPrice = (takerAmount * makerDecimals) / makerAmount;

        require(makerPrice >= priceFloor, "slippage is too high");
    }

    /**
     * @notice Verifies that the signer is the owner of the signing contract.
     */
    function _isValidSignature(
        bytes calldata data,
        bytes calldata signature,
        address signer
    ) internal view returns (bytes4) {
        // 0x trading disabled
        return EIP1271_INVALID_SIG;
    }
}