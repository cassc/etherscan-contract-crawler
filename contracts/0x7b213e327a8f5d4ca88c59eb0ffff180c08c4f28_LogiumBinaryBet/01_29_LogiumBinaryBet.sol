// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * =========================================================================
 * Template Smart Contract Code is legally protected and is the exclusive
 * intellectual property of the Owner. It is prohibited to copy, distribute, or
 * modify the Template Smart Contract Code without the prior written consent of
 * the Owner, except for the purpose for which the Template Smart Contract Code
 * was created, i.e., to reference the Template Smart Contract Code in order to
 * enter into transactions on the LOGIUM platform, under the current terms and
 * conditions permitted by the Owner at the time of entering into the particular
 * smart contract.
 *
 * LOGIUM creates the Template Smart Contract Code, which is provided to the
 * issuer and taker but LOGIUM has no control over the contract they sign. The
 * contract they entered into specifies all the transaction terms, which LOGIUM
 * has no influence on.
 *
 * Users enter into futures contracts - options - with each other, and LOGIUM
 * does not act as a broker in this legal relationship, but only as a provider
 * of the Template Smart Contract Code.
 *
 * Trading is conducted only between users, LOGIUM does not participate in it as
 * a party. LOGIUM's only profit is the commission on a transaction, which is
 * always calculated only on winnings, and is not in the legal nature of a stock
 * exchange commission. The final real value of the fee depends on the amount of
 * leverage set by the user.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./libraries/Constants.BinaryBet.sol";
import "./libraries/OracleLibrary.sol";
import "./libraries/Market.sol";
import "./libraries/RatioMath.sol";
import "./libraries/Ticket.sol";
import "./libraries/TicketBinaryBet.sol";
import "./interfaces/ILogiumBinaryBet.sol";
import "./interfaces/ILogiumCore.sol";

/// @title Binary Bet Logium contract
/// @notice This contract is meant to be deployed as a "masterBet" contract for Logium exchange
/// This contract implements binary bet logic and serves as Template Smart Contract Code
contract LogiumBinaryBet is ILogiumBinaryBet {
    using SafeCast for uint256;
    using TicketBinaryBet for TicketBinaryBet.Details;
    using TicketBinaryBet for bytes;
    using Ticket for Ticket.Immutable;

    /// structure describing bet take(-s) by one trader in one block
    /// Properties:
    /// - amount - total amount in smallest units as described by the RatioMath library
    /// - end - timestamp of expiry
    struct Trade {
        uint128 amount; // bet amount
        uint128 end; // timestamp
    }

    /// Dynamic bet state

    /// @notice expiry of last trade
    uint128 private lastEnd;

    /// @notice total issuer collateral
    uint128 private issued;

    /// @dev map from tradeId as defined by tradeId function to amount and expiry time of each trade/take
    /// @inheritdoc ILogiumBinaryBetState
    mapping(uint256 => Trade) public override traders;

    /// @notice Address of Logium master
    /// @dev immutable values are stored in bytecode, this is inherited by all clones
    address public immutable coreInstance;

    address private immutable betImplementation;

    /// address for transferring collected fees
    /// @dev immutable values are stored in bytecode, this is inherited by all clones
    address public immutable feeCollector;

    /// @dev only allow LogiumCore to call decorated function
    modifier onlyCore() {
        require(msg.sender == coreInstance, "Unauthorized");
        _;
    }

    modifier properTicket(Ticket.Immutable calldata ticket) {
        bytes32 hashVal = ticket.hashValImmutable();
        address expectedAddress = Clones.predictDeterministicAddress(
            betImplementation,
            hashVal,
            coreInstance
        );
        require(address(this) == expectedAddress, "Invalid ticket");
        _;
    }

    constructor(address _coreInstance, address _feeCollector) {
        require(_feeCollector != address(0x0), "Fee collector must be valid");
        coreInstance = _coreInstance;
        feeCollector = _feeCollector;
        lastEnd = type(uint128).max; // prevent expiration on master instance
        betImplementation = address(this);
    }

    function initAndIssue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    ) external override returns (uint256 issuerPrice, uint256 traderPrice) {
        require(lastEnd == 0, "Already initialized"); // check if uninitialized
        // lastEnd is initialized in issue
        return issue(detailsHash, trader, takeParams, volume, detailsEnc);
    }

    function issue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    )
        public
        override
        onlyCore
        returns (uint256 issuerPrice, uint256 traderPrice)
    {
        uint256 amount = uint256(takeParams); //decode takeParams
        TicketBinaryBet.Details memory details = detailsEnc
            .unpackBinaryBetDetails();
        (issuerPrice, traderPrice) = RatioMath.priceFromRatio(
            amount,
            details.ratio
        );
        uint128 newIssuedTotal = issued + issuerPrice.toUint128();
        uint128 end = (block.timestamp + details.period).toUint128();
        uint256 _tradeId = tradeId(trader, block.number);

        require(newIssuedTotal <= volume, "Volume not available");
        require(details.hashDetails() == detailsHash, "Invalid detailsHash");
        require(
            details.issuerWinFee <= Constants.MAX_FEE_X9,
            "Invalid issuer win fee"
        );
        require(
            details.traderWinFee <= Constants.MAX_FEE_X9,
            "Invalid trader win fee"
        );

        (issued, lastEnd) = (newIssuedTotal, end);
        traders[_tradeId] = Trade({
            amount: traders[_tradeId].amount + amount.toUint128(),
            end: end
        });
    }

    function claim(Ticket.Immutable calldata ticket)
        external
        override
        properTicket(ticket)
    {
        require(block.timestamp > lastEnd, "Not expired");
        TicketBinaryBet.Details memory details = ticket
            .details
            .unpackBinaryBetDetails();

        // Recover win amount
        uint256 balance = Constants.USDC.balanceOf(address(this));
        require(balance > 0, "Nothing to claim");
        (uint256 issuerCollateral, uint256 issuerWin) = RatioMath
            .totalStakeToPrice(balance, details.ratio);

        // IssuerWinFee can't be > 10**9 (1 with 9 decimals) due to check in issue,
        // thus this will not overflow for any "issuerWin" under ~10**68.
        // For USDC base currency this is 10**62 USD in value. We do not expect to see such stakes.
        uint256 fee = (issuerWin * details.issuerWinFee) / (10**9);
        uint256 issuerTransfer = issuerCollateral + issuerWin - fee;
        if (details.claimTo != address(0x0)) {
            Constants.USDC.transfer(details.claimTo, issuerTransfer);
        } else {
            Constants.USDC.approve(coreInstance, issuerTransfer);
            ILogiumCore(coreInstance).depositTo(
                ticket.maker,
                issuerTransfer.toUint128()
            );
        }
        if (fee > 0) {
            Constants.USDC.transfer(feeCollector, fee);
        }

        emit Claim();
    }

    function claimableFrom() external view override returns (uint256) {
        return lastEnd;
    }

    function exercise(Ticket.Immutable calldata ticket, uint256 blockNumber)
        external
        override
        properTicket(ticket)
    {
        _doExercise(ticket, tradeId(msg.sender, blockNumber), false);
    }

    function exerciseOther(
        Ticket.Immutable calldata ticket,
        uint256 id,
        bool gasFee
    ) external override properTicket(ticket) {
        _doExercise(ticket, id, gasFee);
    }

    function exerciseWindowDuration(Ticket.Immutable calldata ticket)
        public
        view
        override
        properTicket(ticket)
        returns (uint256)
    {
        return ticket.details.unpackBinaryBetDetails().exerciseWindowDuration;
    }

    function marketTick(Ticket.Immutable calldata ticket)
        public
        view
        override
        properTicket(ticket)
        returns (int24)
    {
        return
            Market.getMarketTickvsUSDC(
                ticket.details.unpackBinaryBetDetails().pool
            );
    }

    function issuerTotal() external view override returns (uint256) {
        return issued;
    }

    function tradersTotal(Ticket.Immutable calldata ticket)
        external
        view
        override
        properTicket(ticket)
        returns (uint256)
    {
        return
            RatioMath.issuerToTrader(
                issued,
                ticket.details.unpackBinaryBetDetails().ratio
            );
    }

    /// @notice Exercise the given trade
    /// @param id trade id
    function _doExercise(
        Ticket.Immutable calldata ticket,
        uint256 id,
        bool gasFee
    ) internal {
        TicketBinaryBet.Details memory details = ticket
            .details
            .unpackBinaryBetDetails();
        (uint256 trader_amount, uint256 trader_end) = (
            traders[id].amount,
            traders[id].end
        );

        require(
            trader_end - details.exerciseWindowDuration < block.timestamp,
            "Too soon to exercise"
        );
        require(trader_amount > 0, "Amount is 0");
        require(block.timestamp <= trader_end, "Contract expired");

        // solhint-disable-next-line var-name-mixedcase
        int24 USDC_WETHTick;
        int24 marketTickVal;
        if (gasFee) {
            (marketTickVal, USDC_WETHTick) = Market
                .getMarketTickvsUSDCwithUSDCWETHTick(details.pool);
        } else {
            marketTickVal = Market.getMarketTickvsUSDC(details.pool);
        }

        if (details.isUp) {
            require(
                marketTickVal >= details.strikeUniswapTick,
                "Strike not passed"
            );
        } else {
            require(
                marketTickVal <= details.strikeUniswapTick,
                "Strike not passed"
            );
        }

        // TraderWinFee can't be > 10**9 (1 with 9 decimals) due to check in issue,
        // thus this will not overflow for any "traderWin" under ~10**68.
        // For USDC base currency this is 10**62 USD in value. We do not expect to see such stakes.
        (uint256 traderWin, uint256 traderCollateral) = RatioMath
            .priceFromRatio(trader_amount, details.ratio);
        uint256 fee = (traderWin * details.traderWinFee) / (10**9);
        if (gasFee) {
            uint256 totalEtherForGas = block.basefee * Constants.EXERCISE_GAS;

            uint160 sqrtRatioX96 = OracleLibrary.getSqrtRatioAtTick(
                USDC_WETHTick
            );
            if (sqrtRatioX96 > 1 << 96) sqrtRatioX96 = (1 << 96) - 1; //cap ratio at "1". This is equivalent to 1ETH = 10^12 USDC (due to decimal point difference)

            uint256 ratioX128 = uint128(
                (uint256(sqrtRatioX96) * uint256(sqrtRatioX96)) >> 64
            ); // doesn't overflow due to above cap

            fee += (ratioX128 * totalEtherForGas) >> 128; //not expected to overflow as this would be equivalent to total USDC cost of transaction > 1e32

            require(
                traderCollateral + traderWin > fee,
                "Exercise would result in loss"
            );
        }

        traders[id].amount = 0;
        traders[id].end = 0;

        Constants.USDC.transfer(
            addressFromId(id),
            traderCollateral + traderWin - fee
        );
        if (fee > 0) {
            Constants.USDC.transfer(feeCollector, fee);
        }
        emit Exercise(id);
    }

    function tradeId(address trader, uint256 blockNumber)
        public
        pure
        override
        returns (uint256)
    {
        require(blockNumber < (1 << 64), "blockNumber too high");
        return (uint256(uint160(trader)) << 64) | blockNumber;
    }

    /// @notice Recover address from trade id
    /// @param id the trade id
    /// @return trader address
    function addressFromId(uint256 id) internal pure returns (address) {
        return address(uint160(id >> 64));
    }

    // solhint-disable-next-line func-name-mixedcase
    function DETAILS_TYPE() external pure override returns (bytes memory) {
        return TicketBinaryBet.DETAILS_TYPE;
    }
}