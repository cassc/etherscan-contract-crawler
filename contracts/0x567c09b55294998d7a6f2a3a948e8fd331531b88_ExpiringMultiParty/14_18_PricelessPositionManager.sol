// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../common/implementation/FixedPoint.sol";
import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/interfaces/IERC20Standard.sol";

import "../../oracle/interfaces/OptimisticOracleInterface.sol";
import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";

import "../../oracle/implementation/Constants.sol";
import "../../common/implementation/Lockable.sol";

import "../common/financial-product-libraries/expiring-multiparty-libraries/FinancialProductLibrary.sol";

/**
 * @title Financial contract with priceless position management.
 * @notice Handles positions for multiple sponsors in an optimistic (i.e., priceless) way without relying
 * on a price feed. On construction, deploys a new ERC20, managed by this contract, that is the synthetic token.
 */

contract PricelessPositionManager is Lockable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;
    using SafeERC20 for ExpandedIERC20;
    using Address for address;

    /****************************************
     *  PRICELESS POSITION DATA STRUCTURES  *
     ****************************************/

    // Stores the state of the PricelessPositionManager. Set on expiration, emergency shutdown, or settlement.
    enum ContractState {
        Open,
        ExpiredPriceRequested,
        ExpiredPriceReceived
    }
    ContractState public contractState;

    // Represents a single sponsor's position. All collateral is held by this contract.
    // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
    struct PositionData {
        FixedPoint.Unsigned tokensOutstanding;
        // Tracks pending withdrawal requests. A withdrawal request is pending if `withdrawalRequestPassTimestamp != 0`.
        uint256 withdrawalRequestPassTimestamp;
        FixedPoint.Unsigned withdrawalRequestAmount;
        // Collateral value.
        FixedPoint.Unsigned collateral;
        // Tracks pending transfer position requests. A transfer position request is pending if `transferPositionRequestPassTimestamp != 0`.
        uint256 transferPositionRequestPassTimestamp;
    }

    // Maps sponsor addresses to their positions. Each sponsor can have only one position.
    mapping(address => PositionData) public positions;

    // Keep track of the total collateral and tokens across all positions to enable calculating the
    // global collateralization ratio without iterating over all positions.
    FixedPoint.Unsigned public totalTokensOutstanding;

    // Total position collateral.
    FixedPoint.Unsigned public totalPositionCollateral;

    // Synthetic token created by this contract.
    ExpandedIERC20 public tokenCurrency;

    // The collateral currency used to back the positions in this contract.
    IERC20 public collateralCurrency;

    // Finder contract used to look up addresses for UMA system contracts.
    FinderInterface public finder;

    // Unique identifier for DVM price feed ticker.
    bytes32 public priceIdentifier;
    // Ancillary data to pass to the Optimistic Oracle system when requesting and fetching prices
    bytes public ancillaryData;

    // Time that this contract expires. Should not change post-construction unless an emergency shutdown occurs.
    uint256 public expirationTimestamp;
    // Time that has to elapse for a withdrawal request to be considered passed, if no liquidations occur.
    // !!Note: The lower the withdrawal liveness value, the more risk incurred by the contract.
    //       Extremely low liveness values increase the chance that opportunistic invalid withdrawal requests
    //       expire without liquidation, thereby increasing the insolvency risk for the contract as a whole. An insolvent
    //       contract is extremely risky for any sponsor or synthetic token holder for the contract.
    uint256 public withdrawalLiveness;

    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned public minSponsorTokens;

    // The expiry price pulled from the DVM.
    FixedPoint.Unsigned public expiryPrice;

    // How much to offer the Optimistic Oracle as a reward for price requests
    FixedPoint.Unsigned public ooReward;

    address public owner;
    // Instance of FinancialProductLibrary to provide custom price and collateral requirement transformations to extend
    // the functionality of the EMP to support a wider range of financial products.
    FinancialProductLibrary public financialProductLibrary;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event RequestTransferPosition(address indexed oldSponsor);
    event RequestTransferPositionExecuted(
        address indexed oldSponsor,
        address indexed newSponsor
    );
    event RequestTransferPositionCanceled(address indexed oldSponsor);
    event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
    event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawal(
        address indexed sponsor,
        uint256 indexed collateralAmount
    );
    event RequestWithdrawalExecuted(
        address indexed sponsor,
        uint256 indexed collateralAmount
    );
    event RequestWithdrawalCanceled(
        address indexed sponsor,
        uint256 indexed collateralAmount
    );
    event PositionCreated(
        address indexed sponsor,
        uint256 indexed collateralAmount,
        uint256 indexed tokenAmount
    );
    event NewSponsor(address indexed sponsor);
    event EndedSponsorPosition(address indexed sponsor);
    event Repay(
        address indexed sponsor,
        uint256 indexed numTokensRepaid,
        uint256 indexed newTokenCount
    );
    event Redeem(
        address indexed sponsor,
        uint256 indexed collateralAmount,
        uint256 indexed tokenAmount
    );
    event ContractExpired(address indexed caller);
    event SettleExpiredPosition(
        address indexed caller,
        uint256 indexed collateralReturned,
        uint256 indexed tokensBurned
    );
    event EmergencyShutdown(
        address indexed caller,
        uint256 originalExpirationTimestamp,
        uint256 shutdownTimestamp
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    modifier onlyPreExpiration() {
        _onlyPreExpiration();
        _;
    }

    modifier onlyPostExpiration() {
        _onlyPostExpiration();
        _;
    }

    modifier onlyCollateralizedPosition(address sponsor) {
        _onlyCollateralizedPosition(sponsor);
        _;
    }

    // Check that the current state of the pricelessPositionManager is Open.
    // This prevents multiple calls to `expire` and `EmergencyShutdown` post expiration.
    modifier onlyOpenState() {
        _onlyOpenState();
        _;
    }

    modifier noPendingWithdrawal(address sponsor) {
        _positionHasNoPendingWithdrawal(sponsor);
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    /**
     * @notice Construct the PricelessPositionManager
     * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
     * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
     * can mint new tokens, which could be used to steal all of this contract's locked collateral.
     * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
     * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
     * total supply is 0 prior to construction of this contract.
     * @param _expirationTimestamp unix timestamp of when the contract will expire.
     * @param _withdrawalLiveness liveness delay, in seconds, for pending withdrawals.
     * @param _collateralAddress ERC20 token used as collateral for all positions.
     * @param _tokenAddress ERC20 token used as synthetic token.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _priceIdentifier registered in the DVM for the synthetic.
     * @param _minSponsorTokens minimum number of tokens that must exist at any time in a position.
     * @param _ooReward How much collateral to offer to the Optimistic Oracle when resolving prices
     * Must be set to 0x0 for production environments that use live time.
     * @param _financialProductLibraryAddress Contract providing contract state transformations.
     */
    constructor(
        uint256 _expirationTimestamp,
        uint256 _withdrawalLiveness,
        address _collateralAddress,
        address _tokenAddress,
        address _finderAddress,
        bytes32 _priceIdentifier,
        FixedPoint.Unsigned memory _minSponsorTokens,
        FixedPoint.Unsigned memory _ooReward,
        address _financialProductLibraryAddress,
        bytes memory _ancillaryData,
        address _owner
    ) nonReentrant() {
        finder = FinderInterface(_finderAddress);

        require(_expirationTimestamp > block.timestamp);
        require(
            _getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier)
        );

        expirationTimestamp = _expirationTimestamp;
        withdrawalLiveness = _withdrawalLiveness;
        tokenCurrency = ExpandedIERC20(_tokenAddress);
        collateralCurrency = IERC20(_collateralAddress);
        minSponsorTokens = _minSponsorTokens;
        ooReward = _ooReward;
        priceIdentifier = _priceIdentifier;
        ancillaryData = _ancillaryData;
        owner = _owner;

        // Initialize the financialProductLibrary at the provided address.
        financialProductLibrary = FinancialProductLibrary(
            _financialProductLibraryAddress
        );
    }

    /****************************************
     *          POSITION FUNCTIONS          *
     ****************************************/

    /**
     * @notice Requests to transfer ownership of the caller's current position to a new sponsor address.
     * Once the request liveness is passed, the sponsor can execute the transfer and specify the new sponsor.
     * @dev The liveness length is the same as the withdrawal liveness.
     */
    function requestTransferPosition() public onlyPreExpiration nonReentrant {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(positionData.transferPositionRequestPassTimestamp == 0);

        // Make sure the proposed expiration of this request is not post-expiry.
        uint256 requestPassTime = (block.timestamp).add(withdrawalLiveness);
        require(requestPassTime < expirationTimestamp);

        // Update the position object for the user.
        positionData.transferPositionRequestPassTimestamp = requestPassTime;

        emit RequestTransferPosition(msg.sender);
    }

    /**
     * @notice After a passed transfer position request (i.e., by a call to `requestTransferPosition` and waiting
     * `withdrawalLiveness`), transfers ownership of the caller's current position to `newSponsorAddress`.
     * @dev Transferring positions can only occur if the recipient does not already have a position.
     * @param newSponsorAddress is the address to which the position will be transferred.
     */
    function transferPositionPassedRequest(address newSponsorAddress)
        public
        onlyPreExpiration
        noPendingWithdrawal(msg.sender)
        nonReentrant
    {
        require(
            positions[newSponsorAddress].collateral.isEqual(
                FixedPoint.fromUnscaledUint(0)
            )
        );
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            positionData.transferPositionRequestPassTimestamp != 0 &&
                positionData.transferPositionRequestPassTimestamp <=
                block.timestamp
        );

        // Reset transfer request.
        positionData.transferPositionRequestPassTimestamp = 0;

        positions[newSponsorAddress] = positionData;
        delete positions[msg.sender];

        emit RequestTransferPositionExecuted(msg.sender, newSponsorAddress);
        emit NewSponsor(newSponsorAddress);
        emit EndedSponsorPosition(msg.sender);
    }

    /**
     * @notice Cancels a pending transfer position request.
     */
    function cancelTransferPosition() external onlyPreExpiration nonReentrant {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(positionData.transferPositionRequestPassTimestamp != 0);

        emit RequestTransferPositionCanceled(msg.sender);

        // Reset withdrawal request.
        positionData.transferPositionRequestPassTimestamp = 0;
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the specified sponsor's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param sponsor the sponsor to credit the deposit to.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function depositTo(
        address sponsor,
        FixedPoint.Unsigned memory collateralAmount
    ) public onlyPreExpiration noPendingWithdrawal(sponsor) nonReentrant {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(sponsor);

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        emit Deposit(sponsor, collateralAmount.rawValue);

        // Move collateral currency from sender to contract.
        collateralCurrency.safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount.rawValue
        );
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the caller's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function deposit(FixedPoint.Unsigned memory collateralAmount) public {
        // This is just a thin wrapper over depositTo that specified the sender as the sponsor.
        depositTo(msg.sender, collateralAmount);
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` from the sponsor's position to the sponsor.
     * @dev Reverts if the withdrawal puts this position's collateralization ratio below the global collateralization
     * ratio. In that case, use `requestWithdrawal`. Might not withdraw the full requested amount to account for precision loss.
     * @param collateralAmount is the amount of collateral to withdraw.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdraw(FixedPoint.Unsigned memory collateralAmount)
        public
        onlyPreExpiration
        noPendingWithdrawal(msg.sender)
        nonReentrant
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(msg.sender);

        // Decrement the sponsor's collateral and global collateral amounts. Check the GCR between decrement to ensure
        // position remains above the GCR within the withdrawal. If this is not the case the caller must submit a request.
        amountWithdrawn = _decrementCollateralBalancesCheckGCR(
            positionData,
            collateralAmount
        );

        emit Withdrawal(msg.sender, amountWithdrawn.rawValue);

        // Move collateral currency from contract to sender.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Starts a withdrawal request that, if passed, allows the sponsor to withdraw` from their position.
     * @dev The request will be pending for `withdrawalLiveness`, during which the position can be liquidated.
     * @param collateralAmount the amount of collateral requested to withdraw
     */
    function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
        public
        onlyPreExpiration
        noPendingWithdrawal(msg.sender)
        nonReentrant
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            collateralAmount.isGreaterThan(0) &&
                collateralAmount.isLessThanOrEqual(positionData.collateral)
        );

        // Make sure the proposed expiration of this request is not post-expiry.
        uint256 requestPassTime = (block.timestamp).add(withdrawalLiveness);
        require(requestPassTime < expirationTimestamp);

        // Update the position object for the user.
        positionData.withdrawalRequestPassTimestamp = requestPassTime;
        positionData.withdrawalRequestAmount = collateralAmount;

        emit RequestWithdrawal(msg.sender, collateralAmount.rawValue);
    }

    /**
     * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and waiting
     * `withdrawalLiveness`), withdraws `positionData.withdrawalRequestAmount` of collateral currency.
     * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
     * amount exceeds the collateral in the position (due to paying fees).
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdrawPassedRequest()
        external
        onlyPreExpiration
        nonReentrant
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            positionData.withdrawalRequestPassTimestamp != 0 &&
                positionData.withdrawalRequestPassTimestamp <= block.timestamp
        );

        // If withdrawal request amount is > position collateral, then withdraw the full collateral amount.
        FixedPoint.Unsigned memory amountToWithdraw;
        if (
            positionData.withdrawalRequestAmount.isGreaterThan(
                positionData.collateral
            )
        ) {
            amountToWithdraw = positionData.collateral;
        } else {
            amountToWithdraw = positionData.withdrawalRequestAmount;
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        amountWithdrawn = _decrementCollateralBalances(
            positionData,
            amountToWithdraw
        );

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);

        // Transfer approved withdrawal amount from the contract to the caller.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);

        emit RequestWithdrawalExecuted(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Cancels a pending withdrawal request.
     */
    function cancelWithdrawal() external nonReentrant {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(positionData.withdrawalRequestPassTimestamp != 0);

        emit RequestWithdrawalCanceled(
            msg.sender,
            positionData.withdrawalRequestAmount.rawValue
        );

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);
    }

    /**
     * @notice Creates tokens by creating a new position or by augmenting an existing position. Pulls `collateralAmount` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
     * @dev Reverts if minting these tokens would put the position's collateralization ratio below the
     * global collateralization ratio. This contract must be approved to spend at least `collateralAmount` of
     * `collateralCurrency`.
     * @dev This contract must have the Minter role for the `tokenCurrency`.
     * @param collateralAmount is the number of collateral tokens to collateralize the position with
     * @param numTokens is the number of tokens to mint from the position.
     */
    function create(
        FixedPoint.Unsigned memory collateralAmount,
        FixedPoint.Unsigned memory numTokens
    ) public onlyPreExpiration nonReentrant {
        PositionData storage positionData = positions[msg.sender];

        // Either the new create ratio or the resultant position CR must be above the current GCR.
        require(
            (_checkCollateralization(
                positionData.collateral.add(collateralAmount),
                positionData.tokensOutstanding.add(numTokens)
            ) || _checkCollateralization(collateralAmount, numTokens)),
            "Insufficient collateral"
        );

        require(
            positionData.withdrawalRequestPassTimestamp == 0,
            "Pending withdrawal"
        );

        if (positionData.tokensOutstanding.isEqual(0)) {
            require(
                numTokens.isGreaterThanOrEqual(minSponsorTokens),
                "Below minimum sponsor position"
            );
            emit NewSponsor(msg.sender);
        }

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        // Add the number of tokens created to the position's outstanding tokens.
        positionData.tokensOutstanding = positionData.tokensOutstanding.add(
            numTokens
        );
        totalTokensOutstanding = totalTokensOutstanding.add(numTokens);

        emit PositionCreated(
            msg.sender,
            collateralAmount.rawValue,
            numTokens.rawValue
        );

        // Transfer tokens into the contract from caller and mint corresponding synthetic tokens to the caller's address.
        collateralCurrency.safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount.rawValue
        );
        require(tokenCurrency.mint(msg.sender, numTokens.rawValue));
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back `collateralCurrency`.
     * This is done by a sponsor to increase position CR. Resulting size is bounded by minSponsorTokens.
     * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt from the sponsor's debt position.
     */
    function repay(FixedPoint.Unsigned memory numTokens)
        public
        onlyPreExpiration
        noPendingWithdrawal(msg.sender)
        nonReentrant
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(numTokens.isLessThanOrEqual(positionData.tokensOutstanding));

        // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
        FixedPoint.Unsigned memory newTokenCount = positionData
            .tokensOutstanding
            .sub(numTokens);
        require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens));
        positionData.tokensOutstanding = newTokenCount;

        // Update the totalTokensOutstanding after redemption.
        totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);

        emit Repay(msg.sender, numTokens.rawValue, newTokenCount.rawValue);

        // Transfer the tokens back from the sponsor and burn them.
        tokenCurrency.safeTransferFrom(
            msg.sender,
            address(this),
            numTokens.rawValue
        );
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of `collateralCurrency`.
     * @dev Can only be called by a token sponsor. Might not redeem the full proportional amount of collateral
     * in order to account for precision loss. This contract must be approved to spend at least `numTokens` of
     * `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function redeem(FixedPoint.Unsigned memory numTokens)
        public
        noPendingWithdrawal(msg.sender)
        nonReentrant
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(!numTokens.isGreaterThan(positionData.tokensOutstanding));

        FixedPoint.Unsigned memory fractionRedeemed = numTokens.div(
            positionData.tokensOutstanding
        );
        FixedPoint.Unsigned memory collateralRedeemed = fractionRedeemed.mul(
            positionData.collateral
        );

        // If redemption returns all tokens the sponsor has then we can delete their position. Else, downsize.
        if (positionData.tokensOutstanding.isEqual(numTokens)) {
            amountWithdrawn = _deleteSponsorPosition(msg.sender);
        } else {
            // Decrement the sponsor's collateral and global collateral amounts.
            amountWithdrawn = _decrementCollateralBalances(
                positionData,
                collateralRedeemed
            );

            // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
            FixedPoint.Unsigned memory newTokenCount = positionData
                .tokensOutstanding
                .sub(numTokens);
            require(
                newTokenCount.isGreaterThanOrEqual(minSponsorTokens),
                "Below minimum sponsor position"
            );
            positionData.tokensOutstanding = newTokenCount;

            // Update the totalTokensOutstanding after redemption.
            totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);
        }

        emit Redeem(msg.sender, amountWithdrawn.rawValue, numTokens.rawValue);

        // Transfer collateral from contract to caller and burn callers synthetic tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(
            msg.sender,
            address(this),
            numTokens.rawValue
        );
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice After a contract has passed expiry all token holders can redeem their tokens for underlying at the
     * prevailing price defined by the DVM from the `expire` function.
     * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the proportional amount of
     * `collateralCurrency`. Might not redeem the full proportional amount of collateral in order to account for
     * precision loss. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function settleExpired()
        external
        onlyPostExpiration
        nonReentrant
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        // If the contract state is open and onlyPostExpiration passed then `expire()` has not yet been called.
        require(contractState != ContractState.Open, "Unexpired position");

        // Get the current settlement price and store it. If it is not resolved will revert.
        if (contractState != ContractState.ExpiredPriceReceived) {
            expiryPrice = _getOraclePrice(expirationTimestamp);
            contractState = ContractState.ExpiredPriceReceived;
        }

        // Get caller's tokens balance and calculate amount of underlying entitled to them.
        FixedPoint.Unsigned memory tokensToRedeem = FixedPoint.Unsigned(
            tokenCurrency.balanceOf(msg.sender)
        );

        FixedPoint.Unsigned memory totalRedeemableCollateral = tokensToRedeem
            .mul(expiryPrice);

        // If the caller is a sponsor with outstanding collateral they are also entitled to their excess collateral after their debt.
        PositionData storage positionData = positions[msg.sender];
        if (positionData.collateral.isGreaterThan(0)) {
            // Calculate the underlying entitled to a token sponsor. This is collateral - debt in underlying.
            FixedPoint.Unsigned memory tokenDebtValueInCollateral = positionData
                .tokensOutstanding
                .mul(expiryPrice);
            FixedPoint.Unsigned memory positionCollateral = positionData
                .collateral;

            // If the debt is greater than the remaining collateral, they cannot redeem anything.
            FixedPoint.Unsigned
                memory positionRedeemableCollateral = tokenDebtValueInCollateral
                    .isLessThan(positionCollateral)
                    ? positionCollateral.sub(tokenDebtValueInCollateral)
                    : FixedPoint.Unsigned(0);

            // Add the number of redeemable tokens for the sponsor to their total redeemable collateral.
            totalRedeemableCollateral = totalRedeemableCollateral.add(
                positionRedeemableCollateral
            );

            // Reset the position state as all the value has been removed after settlement.
            delete positions[msg.sender];
            emit EndedSponsorPosition(msg.sender);
        }

        // Take the min of the remaining collateral and the collateral "owed". If the contract is undercapitalized,
        // the caller will get as much collateral as the contract can pay out.
        FixedPoint.Unsigned memory payout = FixedPoint.min(
            totalPositionCollateral,
            totalRedeemableCollateral
        );

        // Decrement total contract collateral and outstanding debt.
        totalPositionCollateral = totalPositionCollateral.sub(payout);
        amountWithdrawn = payout;
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRedeem);

        emit SettleExpiredPosition(
            msg.sender,
            amountWithdrawn.rawValue,
            tokensToRedeem.rawValue
        );

        // Transfer tokens & collateral and burn the redeemed tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(
            msg.sender,
            address(this),
            tokensToRedeem.rawValue
        );
        tokenCurrency.burn(tokensToRedeem.rawValue);
    }

    /****************************************
     *        GLOBAL STATE FUNCTIONS        *
     ****************************************/

    /**
     * @notice Locks contract state in expired and requests oracle price.
     * @dev this function can only be called once the contract is expired and can't be re-called.
     */
    function expire() external onlyPostExpiration onlyOpenState nonReentrant {
        contractState = ContractState.ExpiredPriceRequested;

        _requestOraclePrice_senderPays(expirationTimestamp);

        emit ContractExpired(msg.sender);
    }

    /**
     * @notice Premature contract settlement under emergency circumstances.
     * @dev Only the governor can call this function as they are permissioned within the `FinancialContractAdmin`.
     * Upon emergency shutdown, the contract settlement time is set to the shutdown time. This enables withdrawal
     * to occur via the standard `settleExpired` function. Contract state is set to `ExpiredPriceRequested`
     * which prevents re-entry into this function or the `expire` function. No fees are paid when calling
     * `emergencyShutdown` as the governor who would call the function would also receive the fees.
     */
    function emergencyShutdown()
        external
        onlyPreExpiration
        onlyOpenState
        onlyOwner
    {
        contractState = ContractState.ExpiredPriceRequested;
        // Expiratory time now becomes the current time (emergency shutdown time).
        // Price requested at this time stamp. `settleExpired` can now withdraw at this timestamp.
        uint256 oldExpirationTimestamp = expirationTimestamp;
        expirationTimestamp = block.timestamp;
        _requestOraclePrice_senderPays(expirationTimestamp);

        emit EmergencyShutdown(
            msg.sender,
            oldExpirationTimestamp,
            expirationTimestamp
        );
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @notice Accessor method to compute a transformed price using the finanicalProductLibrary specified at contract
     * deployment. If no library was provided then no modification to the price is done.
     * @param price input price to be transformed.
     * @param requestTime timestamp the oraclePrice was requested at.
     * @return transformedPrice price with the transformation function applied to it.
     * @dev This method should never revert.
     */

    function transformPrice(
        FixedPoint.Unsigned memory price,
        uint256 requestTime
    ) public view nonReentrantView returns (FixedPoint.Unsigned memory) {
        return _transformPrice(price, requestTime);
    }

    /**
     * @notice Accessor method to compute a transformed price identifier using the finanicalProductLibrary specified
     * at contract deployment. If no library was provided then no modification to the identifier is done.
     * @param requestTime timestamp the identifier is to be used at.
     * @return transformedPrice price with the transformation function applied to it.
     * @dev This method should never revert.
     */
    function transformPriceIdentifier(uint256 requestTime)
        public
        view
        nonReentrantView
        returns (bytes32)
    {
        return _transformPriceIdentifier(requestTime);
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Reduces a sponsor's position and global counters by the specified parameters. Handles deleting the entire
    // position if the entire position is being removed. Does not make any external transfers.
    function _reduceSponsorPosition(
        address sponsor,
        FixedPoint.Unsigned memory tokensToRemove,
        FixedPoint.Unsigned memory collateralToRemove,
        FixedPoint.Unsigned memory withdrawalAmountToRemove
    ) internal {
        PositionData storage positionData = _getPositionData(sponsor);

        // If the entire position is being removed, delete it instead.
        if (
            tokensToRemove.isEqual(positionData.tokensOutstanding) &&
            positionData.collateral.isEqual(collateralToRemove)
        ) {
            _deleteSponsorPosition(sponsor);
            return;
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        _decrementCollateralBalances(positionData, collateralToRemove);

        // Ensure that the sponsor will meet the min position size after the reduction.
        FixedPoint.Unsigned memory newTokenCount = positionData
            .tokensOutstanding
            .sub(tokensToRemove);
        require(
            newTokenCount.isGreaterThanOrEqual(minSponsorTokens),
            "Below minimum sponsor position"
        );
        positionData.tokensOutstanding = newTokenCount;

        // Decrement the position's withdrawal amount.
        positionData.withdrawalRequestAmount = positionData
            .withdrawalRequestAmount
            .sub(withdrawalAmountToRemove);

        // Decrement the total outstanding tokens in the overall contract.
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRemove);
    }

    // Deletes a sponsor's position and updates global counters. Does not make any external transfers.
    function _deleteSponsorPosition(address sponsor)
        internal
        returns (FixedPoint.Unsigned memory)
    {
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        FixedPoint.Unsigned
            memory startingGlobalCollateral = totalPositionCollateral;

        // Remove the collateral and outstanding from the overall total position.
        totalPositionCollateral = totalPositionCollateral.sub(
            positionToLiquidate.collateral
        );
        totalTokensOutstanding = totalTokensOutstanding.sub(
            positionToLiquidate.tokensOutstanding
        );

        // Reset the sponsors position to have zero outstanding and collateral.
        delete positions[sponsor];

        emit EndedSponsorPosition(sponsor);

        // Return amount of collateral deleted from position.
        return startingGlobalCollateral.sub(totalPositionCollateral);
    }

    function _getPositionData(address sponsor)
        internal
        view
        onlyCollateralizedPosition(sponsor)
        returns (PositionData storage)
    {
        return positions[sponsor];
    }

    function _getIdentifierWhitelist()
        internal
        view
        returns (IdentifierWhitelistInterface)
    {
        return
            IdentifierWhitelistInterface(
                finder.getImplementationAddress(
                    OracleInterfaces.IdentifierWhitelist
                )
            );
    }

    function _getOptimisticOracle()
        internal
        view
        returns (OptimisticOracleInterface)
    {
        return
            OptimisticOracleInterface(
                finder.getImplementationAddress(
                    OracleInterfaces.OptimisticOracle
                )
            );
    }

    // Requests a price for transformed `priceIdentifier` at `requestedTime` from the Oracle, charging the caller for the OO proposer reward.
    function _requestOraclePrice_senderPays(uint256 requestedTime) internal {
        OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();

        // Pull final fee from sender
        collateralCurrency.safeTransferFrom(
            msg.sender,
            address(this),
            ooReward.rawValue
        );

        // Increase token allowance to enable the optimistic oracle fee payment.
        collateralCurrency.safeIncreaseAllowance(
            address(optimisticOracle),
            ooReward.rawValue
        );
        optimisticOracle.requestPrice(
            _transformPriceIdentifier(requestedTime),
            requestedTime,
            ancillaryData,
            collateralCurrency,
            ooReward.rawValue
        );
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOraclePrice(uint256 requestedTime)
        internal
        returns (FixedPoint.Unsigned memory)
    {
        // Create an instance of the oracle and get the price. If the price is not resolved revert.
        OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();
        require(
            optimisticOracle.hasPrice(
                address(this),
                _transformPriceIdentifier(requestedTime),
                requestedTime,
                ancillaryData
            )
        );
        int256 optimisticOraclePrice = optimisticOracle.settleAndGetPrice(
            _transformPriceIdentifier(requestedTime),
            requestedTime,
            ancillaryData
        );

        // For now we don't want to deal with negative prices in positions.
        if (optimisticOraclePrice < 0) {
            optimisticOraclePrice = 0;
        }
        return
            _transformPrice(
                FixedPoint.Unsigned(uint256(optimisticOraclePrice)),
                requestedTime
            );
    }

    // Reset withdrawal request by setting the withdrawal request and withdrawal timestamp to 0.
    function _resetWithdrawalRequest(PositionData storage positionData)
        internal
    {
        positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
        positionData.withdrawalRequestPassTimestamp = 0;
    }

    // Ensure individual and global consistency when increasing collateral balances. Returns the change to the position.
    function _incrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        positionData.collateral = positionData.collateral.add(collateralAmount);
        totalPositionCollateral = totalPositionCollateral.add(collateralAmount);
        return collateralAmount;
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the
    // position. We elect to return the amount that the global collateral is decreased by, rather than the individual
    // position's collateral, because we need to maintain the invariant that the global collateral is always
    // <= the collateral owned by the contract to avoid reverts on withdrawals. The amount returned = amount withdrawn.
    function _decrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        positionData.collateral = positionData.collateral.sub(collateralAmount);
        totalPositionCollateral = totalPositionCollateral.sub(collateralAmount);
        return collateralAmount;
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the position.
    // This function is similar to the _decrementCollateralBalances function except this function checks position GCR
    // between the decrements. This ensures that collateral removal will not leave the position undercollateralized.
    function _decrementCollateralBalancesCheckGCR(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        positionData.collateral = positionData.collateral.sub(collateralAmount);
        totalPositionCollateral = totalPositionCollateral.sub(collateralAmount);
        require(_checkPositionCollateralization(positionData), "CR below GCR");
        return collateralAmount;
    }

    // These internal functions are supposed to act identically to modifiers, but re-used modifiers
    // unnecessarily increase contract bytecode size.
    // source: https://blog.polymath.network/solidity-tips-and-tricks-to-save-gas-and-reduce-bytecode-size-c44580b218e6
    function _onlyOpenState() internal view {
        require(
            contractState == ContractState.Open,
            "Contract state is not OPEN"
        );
    }

    function _onlyPreExpiration() internal view {
        require(
            block.timestamp < expirationTimestamp,
            "Only callable pre-expiry"
        );
    }

    function _onlyPostExpiration() internal view {
        require(
            block.timestamp >= expirationTimestamp,
            "Only callable post-expiry"
        );
    }

    function _onlyCollateralizedPosition(address sponsor) internal view {
        require(
            positions[sponsor].collateral.isGreaterThan(0),
            "Position has no collateral"
        );
    }

    // Note: This checks whether an already existing position has a pending withdrawal. This cannot be used on the
    // `create` method because it is possible that `create` is called on a new position (i.e. one without any collateral
    // or tokens outstanding) which would fail the `onlyCollateralizedPosition` modifier on `_getPositionData`.
    function _positionHasNoPendingWithdrawal(address sponsor) internal view {
        require(
            _getPositionData(sponsor).withdrawalRequestPassTimestamp == 0,
            "Pending withdrawal"
        );
    }

    /****************************************
     *          PRIVATE FUNCTIONS          *
     ****************************************/

    function _checkPositionCollateralization(PositionData storage positionData)
        private
        view
        returns (bool)
    {
        return
            _checkCollateralization(
                positionData.collateral,
                positionData.tokensOutstanding
            );
    }

    // Checks whether the provided `collateral` and `numTokens` have a collateralization ratio above the global
    // collateralization ratio.
    function _checkCollateralization(
        FixedPoint.Unsigned memory collateral,
        FixedPoint.Unsigned memory numTokens
    ) private view returns (bool) {
        FixedPoint.Unsigned memory global = _getCollateralizationRatio(
            totalPositionCollateral,
            totalTokensOutstanding
        );
        FixedPoint.Unsigned memory thisChange = _getCollateralizationRatio(
            collateral,
            numTokens
        );
        return !global.isGreaterThan(thisChange);
    }

    function _getCollateralizationRatio(
        FixedPoint.Unsigned memory collateral,
        FixedPoint.Unsigned memory numTokens
    ) private pure returns (FixedPoint.Unsigned memory ratio) {
        if (!numTokens.isGreaterThan(0)) {
            return FixedPoint.fromUnscaledUint(0);
        } else {
            return collateral.div(numTokens);
        }
    }

    // IERC20Standard.decimals() will revert if the collateral contract has not implemented the decimals() method,
    // which is possible since the method is only an OPTIONAL method in the ERC20 standard:
    // https://eips.ethereum.org/EIPS/eip-20#methods.
    function _getSyntheticDecimals(address _collateralAddress)
        public
        view
        returns (uint8 decimals)
    {
        try IERC20Standard(_collateralAddress).decimals() returns (
            uint8 _decimals
        ) {
            return _decimals;
        } catch {
            return 18;
        }
    }

    function _transformPrice(
        FixedPoint.Unsigned memory price,
        uint256 requestTime
    ) internal view returns (FixedPoint.Unsigned memory) {
        if (!address(financialProductLibrary).isContract()) return price;
        try financialProductLibrary.transformPrice(price, requestTime) returns (
            FixedPoint.Unsigned memory transformedPrice
        ) {
            return transformedPrice;
        } catch {
            return price;
        }
    }

    function _transformPriceIdentifier(uint256 requestTime)
        internal
        view
        returns (bytes32)
    {
        if (!address(financialProductLibrary).isContract())
            return priceIdentifier;
        try
            financialProductLibrary.transformPriceIdentifier(
                priceIdentifier,
                requestTime
            )
        returns (bytes32 transformedIdentifier) {
            return transformedIdentifier;
        } catch {
            return priceIdentifier;
        }
    }
}