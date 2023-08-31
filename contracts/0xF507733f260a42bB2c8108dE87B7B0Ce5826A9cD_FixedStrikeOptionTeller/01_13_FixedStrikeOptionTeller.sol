// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {ClonesWithImmutableArgs} from "src/lib/clones/ClonesWithImmutableArgs.sol";

import {IFixedStrikeOptionTeller, IOptionTeller} from "src/interfaces/IFixedStrikeOptionTeller.sol";
import {FixedStrikeOptionToken} from "src/fixed-strike/FixedStrikeOptionToken.sol";

import {TransferHelper} from "src/lib/TransferHelper.sol";
import {FullMath} from "src/lib/FullMath.sol";

/// @title Fixed Strike Option Teller
/// @notice Fixed Strike Option Teller Contract
/// @dev Option Teller contracts handle the deployment, creation, and exercise of option tokens.
///      Option Tokens are ERC20 tokens that represent the right to buy (call) or sell (put) a fixed
///      amount of an asset (payout token) for an amount of another asset (quote token) between two
///      timestamps (eligible and expiry). Option Tokens are denominated in units of the payout token
///      and are created at a 1:1 ratio for the amount of payout tokens to buy or sell.
///      The amount of quote tokens required to exercise (call) or collateralize (put) an option token
///      is called the strike price. Strike prices are denominated in units of the quote token.
///      The Fixed Strike Option Teller implementation creates option tokens that have a fixed strike
///      price that is set at the time of creation.
///
///      In order to create option tokens, an issuer must deploy the specific token configuration on
///      the teller, and then provide collateral to the teller to mint option tokens. The collateral is
///      required to guarantee that the option tokens can be exercised. The collateral required depends on
///      the option type. For call options, the collateral required is an amount of payout tokens equivalent
///      to the amount of option tokens being minted. For put options, the collateral required is an amount
///      of quote tokens equivalent to the amount of option tokens being minted multipled by the strike price.
///      As the name "option" suggests, the holder of an option token has the right, but not the obligation,
///      to exercise the option token within the eligible time window. If the option token is not exercised,
///      the designated "receiver" of the option token exercise proceeds can reclaim the collateral after
///      the expiry timestamp. If an option token is exercised, the holder receives the collateral and the
///      receiver receives the exercise proceeds.
///
/// @author Bond Protocol
contract FixedStrikeOptionTeller is IFixedStrikeOptionTeller, Auth, ReentrancyGuard {
    using TransferHelper for ERC20;
    using FullMath for uint256;
    using ClonesWithImmutableArgs for address;

    /* ========== ERRORS ========== */

    error Teller_NotAuthorized();
    error Teller_TokenDoesNotExist(bytes32 optionHash);
    error Teller_UnsupportedToken(address token);
    error Teller_InvalidParams(uint256 index, bytes value);
    error Teller_OptionExpired(uint48 expiry);
    error Teller_NotEligible(uint48 eligible);
    error Teller_NotExpired(uint48 expiry);
    error Teller_AlreadyReclaimed(FixedStrikeOptionToken optionToken);
    error Teller_PriceOutOfBounds();
    error Teller_InvalidAmount();

    /* ========== EVENTS ========== */
    event WroteOption(uint256 indexed id, address indexed referrer, uint256 amount, uint256 payout);
    event OptionTokenCreated(
        FixedStrikeOptionToken optionToken,
        ERC20 indexed payoutToken,
        ERC20 quoteToken,
        uint48 eligible,
        uint48 indexed expiry,
        address indexed receiver,
        bool call,
        uint256 strikePrice
    );

    /* ========== STATE VARIABLES ========== */

    /// @notice Fee paid to protocol when options are exercised in basis points (3 decimal places).
    uint48 public protocolFee;

    /// @notice Base value used to scale fees. 1e5 = 100%
    uint48 public constant FEE_DECIMALS = 1e5; // one percent equals 1000.

    /// @notice FixedStrikeOptionToken reference implementation (deployed on creation to clone from)
    FixedStrikeOptionToken public immutable optionTokenImplementation;

    /// @notice Minimum duration an option must be eligible to exercise (in seconds)
    uint48 public minOptionDuration;

    /// @notice Fees earned by protocol, by token
    mapping(ERC20 => uint256) public fees;

    /// @notice Fixed strike option tokens (hash of parameters to address)
    mapping(bytes32 => FixedStrikeOptionToken) public optionTokens;

    /// @notice Whether the receiver of an option token has reclaimed the collateral
    mapping(FixedStrikeOptionToken => bool) public collateralClaimed;

    /* ========== CONSTRUCTOR ========== */

    /// @param guardian_    Address of the guardian for Auth
    /// @param authority_   Address of the authority for Auth
    constructor(address guardian_, Authority authority_) Auth(guardian_, authority_) {
        // Explicitly setting protocol fee to zero initially
        protocolFee = 0;

        // Set minimum option duration initially to 1 day (the absolute minimum given timestamp rounding)
        minOptionDuration = uint48(1 days);

        // Deploy option token implementation that clones proxy to
        optionTokenImplementation = new FixedStrikeOptionToken();
    }

    /* ========== CREATE OPTION TOKENS ========== */

    /// @inheritdoc IFixedStrikeOptionTeller
    function deploy(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external override nonReentrant returns (FixedStrikeOptionToken) {
        // If eligible is zero, use current timestamp
        if (eligible_ == 0) eligible_ = uint48(block.timestamp);

        // Eligible and Expiry are rounded to the nearest day at 0000 UTC (in seconds) since
        // option tokens are only unique to a day, not a specific timestamp.
        eligible_ = uint48(eligible_ / 1 days) * 1 days;
        expiry_ = uint48(expiry_ / 1 days) * 1 days;

        // Revert if eligible is in the past, we do this to avoid duplicates tokens with the same parameters otherwise
        // Truncate block.timestamp to the nearest day for comparison
        if (eligible_ < uint48(block.timestamp / 1 days) * 1 days)
            revert Teller_InvalidParams(2, abi.encodePacked(eligible_));

        // Revert if the difference between eligible and expiry is less than min duration or eligible is after expiry
        // Don't need to check expiry against current timestamp since eligible is already checked
        if (eligible_ > expiry_ || expiry_ - eligible_ < minOptionDuration)
            revert Teller_InvalidParams(3, abi.encodePacked(expiry_));

        // Revert if any addresses are zero or the tokens are not contracts
        if (address(payoutToken_) == address(0) || address(payoutToken_).code.length == 0)
            revert Teller_InvalidParams(0, abi.encodePacked(payoutToken_));
        if (address(quoteToken_) == address(0) || address(quoteToken_).code.length == 0)
            revert Teller_InvalidParams(1, abi.encodePacked(quoteToken_));
        if (receiver_ == address(0)) revert Teller_InvalidParams(4, abi.encodePacked(receiver_));

        // Revert if strike price is zero or out of bounds
        uint8 quoteDecimals = quoteToken_.decimals();
        int8 priceDecimals = _getPriceDecimals(strikePrice_, quoteDecimals);
        // We check that the strike pirce is not zero and that the price decimals are not less than half the quote decimals to avoid precision loss
        // For 18 decimal tokens, this means relative prices as low as 1e-9 are supported
        if (strikePrice_ == 0 || priceDecimals < -int8(quoteDecimals / 2))
            revert Teller_InvalidParams(6, abi.encodePacked(strikePrice_));

        // Create option token if one doesn't already exist
        // Timestamps are truncated above to give canonical version of hash
        bytes32 optionHash = _getOptionTokenHash(
            payoutToken_,
            quoteToken_,
            eligible_,
            expiry_,
            receiver_,
            call_,
            strikePrice_
        );

        FixedStrikeOptionToken optionToken = optionTokens[optionHash];

        // If option token doesn't exist, deploy it
        if (address(optionToken) == address(0)) {
            optionToken = _deploy(
                payoutToken_,
                quoteToken_,
                eligible_,
                expiry_,
                receiver_,
                call_,
                strikePrice_
            );

            // Set the domain separator for the option token on creation to save gas on permit approvals
            optionToken.updateDomainSeparator();

            // Store option token against computed hash
            optionTokens[optionHash] = optionToken;

            // Emit event
            emit OptionTokenCreated(
                optionToken,
                payoutToken_,
                quoteToken_,
                eligible_,
                expiry_,
                receiver_,
                call_,
                strikePrice_
            );
        }
        return optionToken;
    }

    function _deploy(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) internal returns (FixedStrikeOptionToken) {
        // All data has been validated prior to entering this function
        // Option token does not exist yet

        // Get name and symbol for option token
        (bytes32 name, bytes32 symbol) = _getNameAndSymbol(
            payoutToken_,
            quoteToken_,
            expiry_,
            call_,
            strikePrice_
        );

        // Deploy option token
        return
            FixedStrikeOptionToken(
                address(optionTokenImplementation).clone(
                    abi.encodePacked(
                        name,
                        symbol,
                        uint8(payoutToken_.decimals()),
                        payoutToken_,
                        quoteToken_,
                        eligible_,
                        expiry_,
                        receiver_,
                        call_,
                        address(this),
                        strikePrice_
                    )
                )
            );
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function create(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external override nonReentrant {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if provided token address does not match stored token address
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // Revert if expiry is in the past
        if (uint256(expiry) <= block.timestamp) revert Teller_OptionExpired(expiry);

        // Transfer in collateral
        // If call option, transfer in payout tokens equivalent to the amount of option tokens being issued
        // If put option, transfer in quote tokens equivalent to the amount of option tokens being issued * strike price
        if (call) {
            // Transfer payout tokens from user
            // Check that amount received is not less than amount expected
            // Handles edge cases like fee-on-transfer tokens (which are not supported)
            uint256 startBalance = payoutToken.balanceOf(address(this));
            payoutToken.safeTransferFrom(msg.sender, address(this), amount_);
            uint256 endBalance = payoutToken.balanceOf(address(this));
            if (endBalance < startBalance + amount_)
                revert Teller_UnsupportedToken(address(payoutToken));
        } else {
            // Calculate amount of quote tokens required to mint
            // We round up here to avoid issues with precision loss which could lead to loss of funds
            // The rounding is small at normal values, but protects against purposefully small values
            uint256 quoteAmount = amount_.mulDivUp(strikePrice, 10 ** decimals);
            if (quoteAmount == 0) revert Teller_InvalidAmount();

            // Transfer quote tokens from user
            // Check that amount received is not less than amount expected
            // Handles edge cases like fee-on-transfer tokens (which are not supported)
            uint256 startBalance = quoteToken.balanceOf(address(this));
            quoteToken.safeTransferFrom(msg.sender, address(this), quoteAmount);
            uint256 endBalance = quoteToken.balanceOf(address(this));
            if (endBalance < startBalance + quoteAmount)
                revert Teller_UnsupportedToken(address(quoteToken));
        }

        // Mint new option tokens to sender
        optionToken.mint(msg.sender, amount_);
    }

    /* ========== EXERCISE OPTION TOKENS ========== */

    /// @inheritdoc IFixedStrikeOptionTeller
    function exercise(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external override nonReentrant {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if token does not match stored token
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // Validate that option token is eligible to be exercised
        if (uint48(block.timestamp) < eligible) revert Teller_NotEligible(eligible);

        // Validate that option token is not expired
        if (uint48(block.timestamp) >= expiry) revert Teller_OptionExpired(expiry);

        // Calculate amount of quote tokens equivalent to amount at strike price
        uint256 quoteAmount = amount_.mulDivUp(strikePrice, 10 ** decimals);

        // If not receiver, require payment
        if (msg.sender != receiver) {
            // If call, transfer in quote tokens equivalent to the amount of option tokens being exercised * strike price
            // If put, transfer in payout tokens equivalent to the amount of option tokens being exercised
            if (call) {
                // Calculate protocol fee
                uint256 fee = (quoteAmount * protocolFee) / FEE_DECIMALS;
                fees[quoteToken] += fee;

                // Transfer proceeds from user
                // Check balances before and after transfer to ensure that the correct amount was transferred
                // @audit this does enable potential malicious option tokens that can't be exercised
                // However, we view it as a "buyer beware" situation that can handled on the front-end
                {
                    uint256 startBalance = quoteToken.balanceOf(address(this));
                    quoteToken.safeTransferFrom(msg.sender, address(this), quoteAmount);
                    uint256 endBalance = quoteToken.balanceOf(address(this));
                    if (endBalance < startBalance + quoteAmount)
                        revert Teller_UnsupportedToken(address(quoteToken));
                }

                // Transfer proceeds minus fee to receiver
                quoteToken.safeTransfer(receiver, quoteAmount - fee);
            } else {
                // Calculate protocol fee (in payout tokens)
                uint256 fee = (amount_ * protocolFee) / FEE_DECIMALS;
                fees[payoutToken] += fee;

                // Transfer proceeds from user
                // Check balances before and after transfer to ensure that the correct amount was transferred
                // @audit this does enable potential malicious option tokens that can't be exercised
                // However, we view it as a "buyer beware" situation that can handled on the front-end
                {
                    uint256 startBalance = payoutToken.balanceOf(address(this));
                    payoutToken.safeTransferFrom(msg.sender, address(this), amount_);
                    uint256 endBalance = payoutToken.balanceOf(address(this));
                    if (endBalance < startBalance + amount_)
                        revert Teller_UnsupportedToken(address(payoutToken));
                }

                // Transfer proceeds minus fee to receiver
                payoutToken.safeTransfer(receiver, amount_ - fee);
            }
        }

        // Burn option tokens
        optionToken.burn(msg.sender, amount_);

        if (call) {
            // Transfer payout tokens to user
            payoutToken.safeTransfer(msg.sender, amount_);
        } else {
            // Transfer quote tokens to user
            quoteToken.safeTransfer(msg.sender, quoteAmount);
        }
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function reclaim(FixedStrikeOptionToken optionToken_) external override nonReentrant {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if token does not match stored token
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // Revert if not expired
        if (uint48(block.timestamp) < expiry) revert Teller_NotExpired(expiry);

        // Revert if caller is not receiver
        if (msg.sender != receiver) revert Teller_NotAuthorized();

        // Revert if collateral has already been reclaimed
        if (collateralClaimed[optionToken]) revert Teller_AlreadyReclaimed(optionToken);

        // Set collateral as reclaimed
        collateralClaimed[optionToken] = true;

        // Transfer remaining collateral to receiver
        uint256 amount = optionToken.totalSupply();
        if (call) {
            payoutToken.safeTransfer(receiver, amount);
        } else {
            // Calculate amount of quote tokens equivalent to amount at strike price
            uint256 quoteAmount = amount.mulDivUp(strikePrice, 10 ** decimals);
            quoteToken.safeTransfer(receiver, quoteAmount);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @inheritdoc IFixedStrikeOptionTeller
    function exerciseCost(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external view returns (ERC20, uint256) {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if token does not match stored token
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // If option is a call, calculate quote tokens required to exercise
        // If option is a put, exercise cost is the same as the option token amount in payout tokens
        if (call) {
            return (quoteToken, amount_.mulDivUp(strikePrice, 10 ** decimals));
        } else {
            return (payoutToken, amount_);
        }
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function getOptionToken(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) public view returns (FixedStrikeOptionToken) {
        // Eligible and Expiry are rounded to the nearest day at 0000 UTC (in seconds) since
        // option tokens are only unique to a day, not a specific timestamp.
        uint48 eligible = uint48(eligible_ / 1 days) * 1 days;
        uint48 expiry = uint48(expiry_ / 1 days) * 1 days;

        // Calculate a hash from the normalized inputs
        bytes32 optionHash = _getOptionTokenHash(
            payoutToken_,
            quoteToken_,
            eligible,
            expiry,
            receiver_,
            call_,
            strikePrice_
        );

        FixedStrikeOptionToken optionToken = optionTokens[optionHash];

        // Revert if token does not exist
        if (address(optionToken) == address(0)) revert Teller_TokenDoesNotExist(optionHash);

        return optionToken;
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function getOptionTokenHash(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external pure returns (bytes32) {
        // Eligible and Expiry are rounded to the nearest day at 0000 UTC (in seconds) since
        // option tokens are only unique to a day, not a specific timestamp.
        uint48 eligible = uint48(eligible_ / 1 days) * 1 days;
        uint48 expiry = uint48(expiry_ / 1 days) * 1 days;

        return
            _getOptionTokenHash(
                payoutToken_,
                quoteToken_,
                eligible,
                expiry,
                receiver_,
                call_,
                strikePrice_
            );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getOptionTokenHash(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    payoutToken_,
                    quoteToken_,
                    eligible_,
                    expiry_,
                    receiver_,
                    call_,
                    strikePrice_
                )
            );
    }

    /// @notice Derive name and symbol of option token
    function _getNameAndSymbol(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint256 expiry_,
        bool call_,
        uint256 strikePrice_
    ) internal view returns (bytes32, bytes32) {
        // Examples
        // WETH call option expiring on 2100-01-01 with strike price of 10_010.50 DAI would be formatted as:
        // Name: "WETH/DAI C 1.001e+4 2100-01-01"
        // Symbol: "oWETH-21000101"
        //
        // WETH put option expiring on 2100-01-01 with strike price of 10.546 DAI would be formatted as:
        // Name: "WETH/DAI P 1.054e+1 2100-01-01"
        // Symbol: "oWETH-21000101"
        //
        // Note: Names are more specific than symbols, but none are guaranteed to be completely unique to a specific oToken.
        // To ensure uniqueness, the option token address and hash identifier should be used.

        // Get the date format from the expiry timestamp.
        // Convert a number of days into a human-readable date, courtesy of BokkyPooBah.
        // Source: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
        string memory yearStr;
        string memory monthStr;
        string memory dayStr;
        {
            int256 __days = int256(expiry_ / 1 days);

            int256 num1 = __days + 68569 + 2440588; // 2440588 = OFFSET19700101
            int256 num2 = (4 * num1) / 146097;
            num1 = num1 - (146097 * num2 + 3) / 4;
            int256 _year = (4000 * (num1 + 1)) / 1461001;
            num1 = num1 - (1461 * _year) / 4 + 31;
            int256 _month = (80 * num1) / 2447;
            int256 _day = num1 - (2447 * _month) / 80;
            num1 = _month / 11;
            _month = _month + 2 - 12 * num1;
            _year = 100 * (num2 - 49) + _year + num1;

            yearStr = _uint2str(uint256(_year) % 10000);
            monthStr = uint256(_month) < 10
                ? string(abi.encodePacked("0", _uint2str(uint256(_month))))
                : _uint2str(uint256(_month));
            dayStr = uint256(_day) < 10
                ? string(abi.encodePacked("0", _uint2str(uint256(_day))))
                : _uint2str(uint256(_day));
        }

        // Format token symbols
        // Symbols longer than 5 characters are truncated, min length would be 1 if tokens have no symbols, max length is 11
        bytes memory tokenSymbols;
        bytes memory payoutSymbol;
        {
            payoutSymbol = bytes(payoutToken_.symbol());
            if (payoutSymbol.length > 5) payoutSymbol = abi.encodePacked(bytes5(payoutSymbol));
            bytes memory quoteSymbol = bytes(quoteToken_.symbol());
            if (quoteSymbol.length > 5) quoteSymbol = abi.encodePacked(bytes5(quoteSymbol));

            tokenSymbols = abi.encodePacked(payoutSymbol, "/", quoteSymbol);
        }

        // Format option type
        bytes1 callPut = call_ ? bytes1("C") : bytes1("P");

        // Format strike price
        // Strike price is formatted as scientific notation to 3 significant figures
        // Will either be 8 or 9 bytes, e.g. 1.056e+1 (8) or 9.745e-12 (9)
        bytes memory strike = _getScientificNotation(strikePrice_, quoteToken_.decimals());

        // Construct name/symbol strings.

        // Name and symbol can each be at most 32 bytes since it is stored as a bytes32
        // Name is formatted as "payoutSymbol/quoteSymbol callPut strikePrice expiry" with the following constraints:
        // payoutSymbol - 5 bytes
        // "/" - 1 byte
        // quoteSymbol - 5 bytes
        // " " - 1 byte
        // callPut - 1 byte
        // " " - 1 byte
        // strikePrice - 8 or 9 bytes, scientific notation to 3 significant figures, e.g. 1.056e+1 (8) or 9.745e-12 (9)
        // " " - 1 byte
        // expiry - 8 bytes, YYYYMMDD
        // Total is 31 or 32 bytes

        // Symbol is formatted as "oPayoutSymbol-expiry" with the following constraints:
        // "o" - 1 byte
        // payoutSymbol - 5 bytes
        // "-" - 1 byte
        // expiry - 8 bytes, YYYYMMDD
        // Total is 15 bytes

        bytes32 name = bytes32(
            abi.encodePacked(
                tokenSymbols,
                " ",
                callPut,
                " ",
                strike,
                " ",
                yearStr,
                monthStr,
                dayStr
            )
        );
        bytes32 symbol = bytes32(
            abi.encodePacked("o", payoutSymbol, "-", yearStr, monthStr, dayStr)
        );

        return (name, symbol);
    }

    /// @notice Helper function to calculate number of price decimals in the provided price
    /// @param price_   The price to calculate the number of decimals for
    /// @return         The number of decimals
    function _getPriceDecimals(uint256 price_, uint8 tokenDecimals_) internal pure returns (int8) {
        int8 decimals;
        while (price_ >= 10) {
            price_ = price_ / 10;
            decimals++;
        }

        // Subtract the stated decimals from the calculated decimals to get the relative price decimals.
        // Required to do it this way vs. normalizing at the beginning since price decimals can be negative.
        return decimals - int8(tokenDecimals_);
    }

    /// @notice Helper function to format a uint256 into scientific notation with 3 significant figures
    /// @param price_           The price to format
    /// @param tokenDecimals_   The number of decimals in the token
    function _getScientificNotation(
        uint256 price_,
        uint8 tokenDecimals_
    ) internal pure returns (bytes memory) {
        // Get a bytes representation of the price in scientific notation with 3 significant figures.
        // 1. Get the number of price decimals
        int8 priceDecimals = _getPriceDecimals(price_, tokenDecimals_);

        // Scientific notation can support up to 2 digit exponents (i.e. price decimals)
        // The bounds for valid prices have been checked earlier when the token was deployed
        // so we don't have to check again here.

        // 2. Get a string of the price decimals and exponent figure
        bytes memory decStr;
        if (priceDecimals < 0) {
            uint256 decimals = uint256(uint8(-priceDecimals));
            decStr = bytes.concat("e-", bytes(_uint2str(decimals)));
        } else {
            uint256 decimals = uint256(uint8(priceDecimals));
            decStr = bytes.concat("e+", bytes(_uint2str(decimals)));
        }

        // 3. Get a string of the leading digits with decimal point
        uint8 priceMagnitude = uint8(int8(tokenDecimals_) + priceDecimals);
        uint256 digits = price_ / (10 ** (priceMagnitude < 3 ? 0 : priceMagnitude - 3));
        bytes memory digitStr = bytes(_uint2str(digits));
        uint256 len = bytes(digitStr).length;
        bytes memory leadingStr = bytes.concat(digitStr[0], ".");
        for (uint256 i = 1; i < len; ++i) {
            leadingStr = bytes.concat(leadingStr, digitStr[i]);
        }

        // 4. Combine and return
        // The bytes string should be at most 9 bytes (e.g. 1.056e-10)
        return bytes.concat(leadingStr, decStr);
    }

    // Some fancy math to convert a uint into a string, courtesy of Provable Things.
    // Updated to work with solc 0.8.0.
    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /* ========== ADMIN & FEES ========== */

    /// @inheritdoc IOptionTeller
    function setMinOptionDuration(uint48 duration_) external override requiresAuth {
        // Must be a minimum of 1 day due to timestamp rounding
        if (duration_ < uint48(1 days)) revert Teller_InvalidParams(0, abi.encodePacked(duration_));
        minOptionDuration = duration_;
    }

    /// @inheritdoc IOptionTeller
    function setProtocolFee(uint48 fee_) external override requiresAuth {
        if (fee_ > 5e3) revert Teller_InvalidParams(0, abi.encodePacked(fee_)); // 5% max
        protocolFee = fee_;
    }

    /// @inheritdoc IOptionTeller
    function claimFees(
        ERC20[] memory tokens_,
        address to_
    ) external override nonReentrant requiresAuth {
        uint256 len = tokens_.length;
        for (uint256 i; i < len; ++i) {
            ERC20 token = tokens_[i];
            uint256 send = fees[token];

            if (send != 0) {
                fees[token] = 0;
                token.safeTransfer(to_, send);
            }
        }
    }
}