// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

// Import external dependencies
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OlympusERC20Token} from "src/external/OlympusERC20.sol";

// Import internal dependencies
import "src/Kernel.sol";
import {MINTRv1} from "modules/MINTR/MINTR.v1.sol";
import {TRSRYv1} from "modules/TRSRY/TRSRY.v1.sol";
import {ROLESv1, RolesConsumer} from "modules/ROLES/OlympusRoles.sol";

// Import interfaces
import {IBondAuctioneer} from "interfaces/IBondAuctioneer.sol";
import {IBondCallback} from "interfaces/IBondCallback.sol";
import {IBondFixedExpiryTeller} from "interfaces/IBondFixedExpiryTeller.sol";
import {IEasyAuction} from "interfaces/IEasyAuction.sol";

/// @title Olympus Bond Manager
/// @notice Olympus Bond Manager (Policy) Contract
contract BondManager is Policy, RolesConsumer {
    // ========= ERRORS ========= //

    error BondManager_TermTooShort();
    error BondManager_InitialPriceTooLow();
    error BondManager_DebtBufferTooLow();
    error BondManager_AuctionTimeTooShort();
    error BondManager_DepositIntervalTooShort();
    error BondManager_DepositIntervalTooLong();
    error BondManager_CancelTimeTooLong();
    error BondManager_MinPctSoldTooLow();

    // ========= EVENTS ========= //

    event BondProtocolMarketLaunched(
        uint256 marketId,
        address bondToken,
        uint256 capacity,
        uint48 bondTerm
    );
    event GnosisAuctionLaunched(
        uint256 marketId,
        address bondToken,
        uint96 capacity,
        uint48 bondTerm
    );

    // ========= DATA STRUCTURES ========= //

    struct FixedExpiryParameters {
        uint256 initialPrice;
        uint256 minPrice;
        uint48 auctionTime;
        uint32 debtBuffer;
        uint32 depositInterval;
        bool capacityInQuote;
    }

    struct BatchAuctionParameters {
        uint48 auctionCancelTime;
        uint48 auctionTime;
        uint96 minPctSold;
        uint256 minBuyAmount;
        uint256 minFundingThreshold;
    }

    // ========= STATE ========= //

    // Modules
    MINTRv1 public MINTR;
    TRSRYv1 public TRSRY;

    // Policies
    IBondCallback public bondCallback;

    // External Contracts
    IBondAuctioneer public fixedExpiryAuctioneer;
    IBondFixedExpiryTeller public fixedExpiryTeller;
    IEasyAuction public gnosisEasyAuction;

    // Tokens
    OlympusERC20Token public ohm;

    // Market Parameters
    FixedExpiryParameters public fixedExpiryParameters;
    BatchAuctionParameters public batchAuctionParameters;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        address fixedExpiryAuctioneer_,
        address fixedExpiryTeller_,
        address gnosisEasyAuction_,
        address ohm_
    ) Policy(kernel_) {
        fixedExpiryAuctioneer = IBondAuctioneer(fixedExpiryAuctioneer_);
        fixedExpiryTeller = IBondFixedExpiryTeller(fixedExpiryTeller_);
        gnosisEasyAuction = IEasyAuction(gnosisEasyAuction_);
        ohm = OlympusERC20Token(ohm_);
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](3);
        dependencies[0] = toKeycode("MINTR");
        dependencies[1] = toKeycode("TRSRY");
        dependencies[2] = toKeycode("ROLES");

        MINTR = MINTRv1(getModuleAddress(dependencies[0]));
        TRSRY = TRSRYv1(getModuleAddress(dependencies[1]));
        ROLES = ROLESv1(getModuleAddress(dependencies[2]));
    }

    /// @inheritdoc Policy
    function requestPermissions() external view override returns (Permissions[] memory requests) {
        Keycode MINTR_KEYCODE = MINTR.KEYCODE();

        requests = new Permissions[](4);
        requests[0] = Permissions(MINTR_KEYCODE, MINTR.mintOhm.selector);
        requests[1] = Permissions(MINTR_KEYCODE, MINTR.burnOhm.selector);
        requests[2] = Permissions(MINTR_KEYCODE, MINTR.increaseMintApproval.selector);
        requests[3] = Permissions(MINTR_KEYCODE, MINTR.decreaseMintApproval.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @notice                 Creates a market on the Bond Protocol contracts to auction off OHM bonds
    /// @param capacity_        The budget of OHM to payout through OHM bonds
    /// @param bondTerm_        How long should the OHM be locked in the bond
    function createFixedExpiryBondMarket(uint256 capacity_, uint48 bondTerm_)
        external
        onlyRole("bondmanager_admin")
        returns (uint256 marketId)
    {
        // Validate parameters
        if (bondTerm_ < fixedExpiryParameters.auctionTime + 1 days)
            revert BondManager_TermTooShort();
        if (fixedExpiryParameters.initialPrice < fixedExpiryParameters.minPrice)
            revert BondManager_InitialPriceTooLow();
        if (fixedExpiryParameters.debtBuffer < 10_000) revert BondManager_DebtBufferTooLow();
        if (fixedExpiryParameters.auctionTime < 1 days) revert BondManager_AuctionTimeTooShort();
        if (fixedExpiryParameters.depositInterval < 1 hours)
            revert BondManager_DepositIntervalTooShort();
        if (fixedExpiryParameters.depositInterval > fixedExpiryParameters.auctionTime)
            revert BondManager_DepositIntervalTooLong();

        // Encodes the information needed for creating a bond market on Bond Protocol
        bytes memory createMarketParams = abi.encode(
            ERC20(address(ohm)), // payoutToken
            ERC20(address(ohm)), // quoteToken
            address(bondCallback), // callbackAddress
            fixedExpiryParameters.capacityInQuote, // capacityInQuote
            capacity_, // capacity
            fixedExpiryParameters.initialPrice, // formattedInitialPrice
            fixedExpiryParameters.minPrice, // formattedMinimumPrice
            fixedExpiryParameters.debtBuffer, // debtBuffer
            uint48(block.timestamp) + bondTerm_, // vesting
            uint48(block.timestamp) + fixedExpiryParameters.auctionTime, // conclusion
            fixedExpiryParameters.depositInterval, // depositInterval
            int8(0)
        );

        marketId = fixedExpiryAuctioneer.createMarket(createMarketParams);
        bondCallback.whitelist(address(fixedExpiryTeller), marketId);

        // Get the address of the bond token to emit in the event
        ERC20 bondToken = fixedExpiryTeller.getBondTokenForMarket(marketId);

        emit BondProtocolMarketLaunched(marketId, address(bondToken), capacity_, bondTerm_);
    }

    /// @notice                 Creates a bond token using Bond Protocol and creates a Gnosis Auction to sell it
    /// @param capacity_        The amount of OHM to use in the OHM bonds
    /// @param bondTerm_        How long should the OHM be locked in the bond
    function createBatchAuction(uint96 capacity_, uint48 bondTerm_)
        external
        onlyRole("bondmanager_admin")
        returns (uint256 auctionId)
    {
        // Validate parameters
        if (bondTerm_ < batchAuctionParameters.auctionTime) revert BondManager_TermTooShort();
        if (batchAuctionParameters.auctionCancelTime > batchAuctionParameters.auctionTime)
            revert BondManager_CancelTimeTooLong();
        if (batchAuctionParameters.minPctSold == 0) revert BondManager_MinPctSoldTooLow();

        // Pre-mint OHM for the auction
        MINTR.increaseMintApproval(address(this), capacity_);
        MINTR.mintOhm(address(this), capacity_);

        uint48 expiry = uint48(block.timestamp) + batchAuctionParameters.auctionTime + bondTerm_;

        // Create bond token and pre-mint the necessary bond token amount using OHM
        ohm.increaseAllowance(address(fixedExpiryTeller), capacity_);
        ERC20 bondToken = fixedExpiryTeller.deploy(ERC20(address(ohm)), expiry);
        fixedExpiryTeller.create(ERC20(address(ohm)), expiry, capacity_);

        // Launch Gnosis Auction
        bondToken.approve(address(gnosisEasyAuction), capacity_);
        auctionId = gnosisEasyAuction.initiateAuction(
            bondToken, // auctioningToken
            ERC20(address(ohm)), // biddingToken
            block.timestamp + batchAuctionParameters.auctionCancelTime, // last order cancellation time
            block.timestamp + batchAuctionParameters.auctionTime, // auction end time
            capacity_, // auctioned amount of bondToken
            (capacity_ * batchAuctionParameters.minPctSold) / 100, // minimum tokens bought for auction to be valid
            batchAuctionParameters.minBuyAmount, // minimum purchase size of auctioning token
            batchAuctionParameters.minFundingThreshold, // minimum funding threshold
            false, // is atomic closure allowed
            address(0), // access manager contract
            new bytes(0) // access manager contract data
        );

        emit GnosisAuctionLaunched(auctionId, address(bondToken), capacity_, bondTerm_);
    }

    /// @notice                 Closes the specified bond protocol market to prevent future purchases
    /// @param marketId_        The ID of the Bond Protocol auction
    function closeFixedExpiryBondMarket(uint256 marketId_) external onlyRole("bondmanager_admin") {
        fixedExpiryAuctioneer.closeMarket(marketId_);
    }

    /// @notice                 Settles the Gnosis Auction to find the clearing order and allow users to claim their bond tokens
    /// @param auctionId_       The ID of the Gnosis auction
    function settleBatchAuction(uint256 auctionId_) external onlyRole("bondmanager_admin") {
        gnosisEasyAuction.settleAuction(auctionId_);
        uint256 currentBalance = ohm.balanceOf(address(this));
        ohm.transfer(address(TRSRY), currentBalance);
    }

    //============================================================================================//
    //                                      ADMIN FUNCTIONS                                       //
    //============================================================================================//

    /// @notice                     Sets the parameters that will likely be consistent across Bond Protocol market launches
    /// @param initialPrice_        The initial ratio of OHM to OHM bonds that the bonds will sell for
    /// @param minPrice_            The minim ratio of OHM to OHM bonds that the bonds will sell for
    /// @param auctionTime_         How long should the auctioning of the bond tokens last (should be less than planned bond terms)
    /// @param debtBuffer_          Variable used to calculate maximum capacity (should generally be set to 100_000)
    /// @param depositInterval_     Desired frequency of purchases
    function setFixedExpiryParameters(
        uint256 initialPrice_,
        uint256 minPrice_,
        uint48 auctionTime_,
        uint32 debtBuffer_,
        uint32 depositInterval_,
        bool capacityInQuote_
    ) external onlyRole("bondmanager_admin") {
        fixedExpiryParameters = FixedExpiryParameters({
            initialPrice: initialPrice_,
            minPrice: minPrice_,
            auctionTime: auctionTime_,
            debtBuffer: debtBuffer_,
            depositInterval: depositInterval_,
            capacityInQuote: capacityInQuote_
        });
    }

    /// @notice                     Sets the parameters that will likely be consistent across Gnosis Auction launches
    /// @param auctionCancelTime_   How long should users have to cancel their bids (should be less than auctionTime_)
    /// @param auctionTime_         How long should the auctioning of the bond tokens last (should be less than planned bond terms)
    /// @param minPctSold_          What percent of capacity is the minimum acceptable level to sell (2 decimals, i.e. 50 = 50%)
    /// @param minBuyAmount_        Minimum purchase size (in OHM) from a user
    /// @param minFundingThreshold_ Minimum funding threshold
    function setBatchAuctionParameters(
        uint48 auctionCancelTime_,
        uint48 auctionTime_,
        uint96 minPctSold_,
        uint256 minBuyAmount_,
        uint256 minFundingThreshold_
    ) external onlyRole("bondmanager_admin") {
        batchAuctionParameters = BatchAuctionParameters({
            auctionCancelTime: auctionCancelTime_,
            auctionTime: auctionTime_,
            minPctSold: minPctSold_,
            minBuyAmount: minBuyAmount_,
            minFundingThreshold: minFundingThreshold_
        });
    }

    /// @notice                     Sets the bond callback policy for use in minting upon Bond Protocol market purchases
    /// @param newCallback_         The bond callback address to set
    function setCallback(IBondCallback newCallback_) external onlyRole("bondmanager_admin") {
        bondCallback = newCallback_;
    }

    //============================================================================================//
    //                                   EMERGENCY FUNCTIONS                                      //
    //============================================================================================//

    /// @notice                     Blacklists the specified market to prevent the bond callback from minting more OHM on purchases
    /// @param marketId_            The ID of the Bond Protocol auction to shutdown
    function emergencyShutdownFixedExpiryMarket(uint256 marketId_)
        external
        onlyRole("bondmanager_admin")
    {
        bondCallback.blacklist(address(fixedExpiryTeller), marketId_);
        fixedExpiryAuctioneer.closeMarket(marketId_);
    }

    /// @notice                     Increases a contract's allowance to spend the Bond Manager's OHM
    /// @param contract_            The contract to give spending permission to
    /// @param amount_              The amount to increase the OHM spending permission by
    /// @dev                        This shouldn't be needed but is a safegaurd in the event of accounting errors in the market creation functions
    function emergencySetApproval(address contract_, uint256 amount_)
        external
        onlyRole("bondmanager_admin")
    {
        ohm.increaseAllowance(contract_, amount_);
    }

    /// @notice                     Sends OHM from the Bond Manager back to the treasury
    /// @param amount_              The amount of OHM to send to the treasury
    function emergencyWithdraw(uint256 amount_) external onlyRole("bondmanager_admin") {
        ohm.transfer(address(TRSRY), amount_);
    }
}