// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

import {IBondCallback} from "interfaces/IBondCallback.sol";
import {IBondAggregator} from "interfaces/IBondAggregator.sol";

import {TRSRYv1} from "modules/TRSRY/TRSRY.v1.sol";
import {MINTRv1} from "modules/MINTR/MINTR.v1.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";

import {Operator} from "policies/Operator.sol";
import "src/Kernel.sol";

import {TransferHelper} from "libraries/TransferHelper.sol";
import {FullMath} from "libraries/FullMath.sol";

/// @title Olympus Bond Callback
contract BondCallback is Policy, ReentrancyGuard, IBondCallback, RolesConsumer {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    // =========  ERRORS ========= //

    error Callback_MarketNotSupported(uint256 id);
    error Callback_TokensNotReceived();
    error Callback_InvalidParams();

    // =========  STATE ========= //

    mapping(address => mapping(uint256 => bool)) public approvedMarkets;
    mapping(uint256 => uint256[2]) internal _amountsPerMarket;
    mapping(ERC20 => uint256) public priorBalances;

    TRSRYv1 public TRSRY;
    MINTRv1 public MINTR;

    Operator public operator;

    IBondAggregator public aggregator;
    ERC20 public ohm;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        IBondAggregator aggregator_,
        ERC20 ohm_
    ) Policy(kernel_) {
        aggregator = aggregator_;
        ohm = ohm_;
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](3);
        dependencies[0] = toKeycode("TRSRY");
        dependencies[1] = toKeycode("MINTR");
        dependencies[2] = toKeycode("ROLES");

        TRSRY = TRSRYv1(getModuleAddress(dependencies[0]));
        MINTR = MINTRv1(getModuleAddress(dependencies[1]));
        ROLES = ROLESv1(getModuleAddress(dependencies[2]));

        // Approve MINTR for burning OHM (called here so that it is re-approved on updates)
        ohm.safeApprove(address(MINTR), type(uint256).max);
    }

    /// @inheritdoc Policy
    function requestPermissions() external view override returns (Permissions[] memory requests) {
        Keycode TRSRY_KEYCODE = TRSRY.KEYCODE();
        Keycode MINTR_KEYCODE = MINTR.KEYCODE();

        requests = new Permissions[](5);
        requests[0] = Permissions(TRSRY_KEYCODE, TRSRY.increaseWithdrawApproval.selector);
        requests[1] = Permissions(TRSRY_KEYCODE, TRSRY.withdrawReserves.selector);
        requests[2] = Permissions(MINTR_KEYCODE, MINTR.mintOhm.selector);
        requests[3] = Permissions(MINTR_KEYCODE, MINTR.burnOhm.selector);
        requests[4] = Permissions(MINTR_KEYCODE, MINTR.increaseMintApproval.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc IBondCallback
    function whitelist(address teller_, uint256 id_)
        external
        override
        onlyRole("callback_whitelist")
    {
        // Check that the teller matches the aggregator provided teller for the market ID
        if (teller_ != address(aggregator.getTeller(id_))) revert Callback_InvalidParams();

        // Whitelist market for callback
        approvedMarkets[teller_][id_] = true;

        // Get payout capacity required for market
        // If the capacity is in the payout token, then we need approval for the capacity amount
        // If the capacity is in the quote token, then we need approval for capacity / minPrice * scale
        //     since this is the maximum amount of payout tokens that could be received
        // TODO determine if this format is better than importing the BaseBondSDA contract and casting the returned Auctioneer
        (bool success, bytes memory data) = address(aggregator.getAuctioneer(id_)).call(
            abi.encodeWithSignature("markets(uint256)", id_)
        );

        if (!success) revert Callback_InvalidParams();
        (
            ,
            ERC20 payoutToken,
            ,
            ,
            bool capacityInQuote,
            uint256 capacity,
            ,
            uint256 minPrice,
            ,
            ,
            ,
            uint256 scale
        ) = abi.decode(
                data,
                (
                    address,
                    ERC20,
                    ERC20,
                    address,
                    bool,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256
                )
            );

        uint256 toApprove = capacityInQuote ? capacity.mulDiv(scale, minPrice) : capacity;

        // If payout token is in OHM, request mint approval for the capacity in OHM
        // Otherwise, request withdrawal approval for the capacity from the TRSRY
        if (address(payoutToken) == address(ohm)) {
            MINTR.increaseMintApproval(address(this), toApprove);
        } else {
            TRSRY.increaseWithdrawApproval(address(this), payoutToken, toApprove);
        }
    }

    /// @notice Remove a market ID on a teller from the whitelist
    /// @dev    Shutdown function in case there's an issue with the teller
    /// @param  teller_ Address of the Teller contract which serves the market
    /// @param  id_     ID of the market to remove from whitelist
    function blacklist(address teller_, uint256 id_)
        external
        override
        onlyRole("callback_whitelist")
    {
        // Check that the teller matches the aggregator provided teller for the market ID
        if (teller_ != address(aggregator.getTeller(id_))) revert Callback_InvalidParams();

        // Remove market from whitelist
        approvedMarkets[teller_][id_] = false;
    }

    /// @inheritdoc IBondCallback
    function callback(
        uint256 id_,
        uint256 inputAmount_,
        uint256 outputAmount_
    ) external override nonReentrant {
        /// Confirm that the teller and market id are whitelisted
        if (!approvedMarkets[msg.sender][id_]) revert Callback_MarketNotSupported(id_);

        // Get tokens for market
        (, , ERC20 payoutToken, ERC20 quoteToken, , ) = aggregator
            .getAuctioneer(id_)
            .getMarketInfoForPurchase(id_);

        // Check that quoteTokens were transferred prior to the call
        if (quoteToken.balanceOf(address(this)) < priorBalances[quoteToken] + inputAmount_)
            revert Callback_TokensNotReceived();

        // Handle payout
        if (quoteToken == payoutToken && quoteToken == ohm) {
            // If OHM-OHM bond, burn OHM received and then mint OHM to the Teller
            // We don't mint the difference because there could be rare cases where input is greater than output
            MINTR.burnOhm(address(this), inputAmount_);
            MINTR.mintOhm(msg.sender, outputAmount_);
        } else if (quoteToken == ohm) {
            // If inverse bond (buying ohm), transfer payout tokens to sender
            TRSRY.withdrawReserves(msg.sender, payoutToken, outputAmount_);

            // Burn OHM received from sender
            MINTR.burnOhm(address(this), inputAmount_);
        } else if (payoutToken == ohm) {
            // Else (selling ohm), mint OHM to sender
            MINTR.mintOhm(msg.sender, outputAmount_);
        } else {
            // Revert since this callback only handles OHM bonds
            revert Callback_MarketNotSupported(id_);
        }

        // Store amounts in/out.
        // Updated after internal call so previous balances are available to check against
        priorBalances[quoteToken] = quoteToken.balanceOf(address(this));
        priorBalances[payoutToken] = payoutToken.balanceOf(address(this));
        _amountsPerMarket[id_][0] += inputAmount_;
        _amountsPerMarket[id_][1] += outputAmount_;

        // Check if the market is deployed by range operator and update capacity if so
        operator.bondPurchase(id_, outputAmount_);
    }

    /// @notice Send tokens to the TRSRY in a batch
    /// @param  tokens_ - Array of tokens to send
    function batchToTreasury(ERC20[] memory tokens_) external onlyRole("callback_admin") {
        ERC20 token;
        uint256 balance;
        uint256 len = tokens_.length;
        for (uint256 i; i < len; ) {
            token = tokens_[i];
            balance = token.balanceOf(address(this));
            token.safeTransfer(address(TRSRY), balance);
            priorBalances[token] = token.balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    //============================================================================================//
    //                                      ADMIN FUNCTIONS                                       //
    //============================================================================================//

    /// @notice Sets the operator contract for the callback to use to report bond purchases
    /// @notice Must be set before the callback is used
    /// @param  operator_ - Address of the Operator contract
    function setOperator(Operator operator_) external onlyRole("callback_admin") {
        if (address(operator_) == address(0)) revert Callback_InvalidParams();
        operator = operator_;
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc IBondCallback
    function amountsForMarket(uint256 id_)
        external
        view
        override
        returns (uint256 in_, uint256 out_)
    {
        uint256[2] memory marketAmounts = _amountsPerMarket[id_];
        return (marketAmounts[0], marketAmounts[1]);
    }
}