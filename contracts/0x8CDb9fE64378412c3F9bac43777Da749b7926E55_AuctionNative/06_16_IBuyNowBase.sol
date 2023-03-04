// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./ISignableStructsBuyNow.sol";

/**
 * @title Interface to base Escrow Contract for Payments in BuyNow mode.
 * @author Freeverse.io, www.freeverse.io
 * @dev The contract that implements this interface only operates the BuyNow path of a payment;
 * it derives from previously audited code, except for minimal method name changes and
 * several methods changed from 'private' to 'internal'
 * The contract that implements this interface can be inherited to:
 * - conduct buyNows in either native crypto or ERC20 tokens
 * - add more elaborated payment processes (such as Auctions)
 *
 * The contract that implements this interface operates as an escrow
 * for paying for assets in BuyNow mode: the first buyer that
 * executes the buyNow method gets the asset.
 *
 * ROLES: Buyers/bidders explicitly sign the agreement to let the specified Operator address
 * act as an Oracle, responsible for signing the success or failure of the asset transfer,
 * which is conducted outside this contract upon reception of funds.
 *
 * If no confirmation is received from the Operator during the PaymentWindow,
 * all funds received from the buyer are made available to him/her for refund.
 * Throughout the contract, this moment is labeled as 'expirationTime'.
 *
 * To start a payment, signatures of both the buyer and the Operator are required, and they
 * are checked in the contracts that inherit from this one.
 *
 * The contract that implements this interface maintains the balances of all users,
 * which can be withdrawn via explicit calls to the various 'withdraw' methods.
 * If a buyer has a non-zero local balance at the moment of starting a new payment,
 * the contract reuses it, and only requires the provision of the remainder funds required (if any).
 *
 * Each BuyNow has the following State Machine:
 * - NOT_STARTED -> ASSET_TRANSFERRING, triggered by buyNow
 * - ASSET_TRANSFERRING -> PAID, triggered by relaying assetTransferSuccess signed by Operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by relaying assetTransferFailed signed by Operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by a refund request after expirationTime
 *
 * NOTE: To ensure that the payment process proceeds as expected when the payment starts,
 * upon acceptance of a payment, the following data: {operator, feesCollector, expirationTime}
 * is stored in the payment struct, and used throughout the payment, regardless of
 * any possible modifications to the contract's storage.
 *
 * NOTE: The contract allows a feature, 'Seller Registration', that can be used in the scenario that
 * applications want users to prove that they have enough crypto know-how (obtain native crypto,
 * pay for gas using a web3 wallet, etc.) to interact by themselves with this smart contract before selling,
 * so that they are less likely to require technical help in case they need to withdraw funds.
 * - If _isSellerRegistrationRequired = true, this feature is enabled, and payments can only be initiated
 *    if the payment seller has previously executed the registerAsSeller method.
 * - If _isSellerRegistrationRequired = false, this feature is disabled, and payments can be initiated
 *    regardless of any previous call to the registerAsSeller method.
 *
 * NOTE: Following audits suggestions, the EIP712 contract, which uses OpenZeppelin's implementation,
 * is not inherited; it is separately deployed, so that it can be upgraded should the standard evolve in the future.
 *
 */

interface IBuyNowBase is ISignableStructsBuyNow {
    /**
     * @dev Event emitted on change of EIP712 verifier contract address
     * @param eip712address The address of the new EIP712 verifier contract
     * @param prevEip712address The previous value of eip712address
     */

    event EIP712(address eip712address, address prevEip712address);

    /**
     * @dev Event emitted on change of payment window
     * @param window The new amount of time after the arrival of a payment for which,
     *  in absence of confirmation of asset transfer success, a buyer is allowed to refund
     * @param prevWindow The previous value of window
     */
    event PaymentWindow(uint256 window, uint256 prevWindow);

    /**
     * @dev Event emitted on change of maximum fee BPS that can be accepted in any payment
     * @param maxFeeBPS the max fee (in BPS units) that can be accepted in any payment
     *  despite operator and buyer having signed a larger amount;
     *  a value of 10000 BPS would correspond to 100% (no limit at all)
     * @param prevMaxFeeBPS The previous value of maxFeeBPS
     */
    event MaxFeeBPS(uint256 maxFeeBPS, uint256 prevMaxFeeBPS);

    /**
     * @dev Event emitted when a user executes the registerAsSeller method
     * @param seller The address of the newly registeredAsSeller user.
     */
    event NewSeller(address indexed seller);

    /**
     * @dev Event emitted when a user sets a value of onlyUserCanWithdraw
     *  - if true: only the user can execute withdrawals of his/her local balance
     *  - if false: any address can help and execute the withdrawals on behalf of the user
     *   (the funds still go straight to the user, but the helper address covers gas costs
     *    and the hassle of executing the transaction)
     * @param user The address of the user.
     * @param onlyUserCanWithdraw true if only the user can execute withdrawals of his/her local balance
     * @param prevOnlyUserCanWithdraw the previous value, overwritten by 'onlyUserCanWithdraw'
     */
    event OnlyUserCanWithdraw(address indexed user, bool onlyUserCanWithdraw, bool prevOnlyUserCanWithdraw);

    /**
     * @dev Event emitted when a buyer is refunded for a given payment process
     * @param paymentId The id of the already initiated payment
     * @param buyer The address of the refunded buyer
     */
    event BuyerRefunded(bytes32 indexed paymentId, address indexed buyer);

    /**
     * @dev Event emitted when funds for a given payment arrive to this contract
     * @param paymentId The unique id identifying the payment
     * @param buyer The address of the buyer providing the funds
     * @param seller The address of the seller of the asset
     */
    event BuyNow(
        bytes32 indexed paymentId,
        address indexed buyer,
        address indexed seller
    );

    /**
     * @dev Event emitted when a payment process arrives at the PAID
     *  final state, where the seller receives the funds.
     * @param paymentId The id of the already initiated payment
     */
    event Paid(bytes32 indexed paymentId);

    /**
     * @dev Event emitted when user withdraws funds from this contract
     * @param user The address of the user that withdraws
     * @param amount The amount withdrawn, in lowest units of the currency
     */
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev The enum characterizing the possible states of an payment process
     */
    enum State {
        NotStarted,
        AssetTransferring,
        Refunded,
        Paid,
        Auctioning
    }

    /**
     * @notice Main struct stored with every payment.
     *  All variables of the struct remain immutable throughout a payment process
     *  except for `state`.
     */
    struct Payment {
        // the current state of the payment process
        State state;

        // the buyer, providing the required funds, who shall receive
        // the asset on a successful payment.
        address buyer;

        // the seller of the asset, who shall receive the funds
        // (subtracting fees) on a successful payment.        
        address seller;

        // the id of the universe that the asset belongs to.
        uint256 universeId;

        // The address of the feesCollector of this payment
        address feesCollector;

        // The timestamp after which, in absence of confirmation of 
        // asset transfer success, a buyer is allowed to refund
        uint256 expirationTime;

        // the percentage fee expressed in Basis Points (bps), typical in finance
        // Examples:  2.5% = 250 bps, 10% = 1000 bps, 100% = 10000 bps
        uint256 feeBPS;

        // the price of the asset, an integer expressed in the
        // lowest unit of the currency.
        uint256 amount;
    }

    /**
     * @notice Registers msg.sender as seller so that, if the contract has set
     *  _isSellerRegistrationRequired = true, then payments will be accepted with
     *  msg.sender as seller.
    */
    function registerAsSeller() external;

    /**
     * @notice Sets the value of onlyUserCanWithdraw for the user with msg.sender address:
     *  - if true: only the user can execute withdrawals of his/her local balance
     *  - if false: any address can help and execute the withdrawals on behalf of the user
     *   (the funds still go straight to the user, but the helper address covers gas costs
     *    and the hassle of executing the transaction)
     * @param onlyUserCan true if only the user can execute withdrawals of his/her local balance
     */
    function setOnlyUserCanWithdraw(bool onlyUserCan) external;

    /**
     * @notice Relays the operator signature declaring that the asset transfer was successful or failed,
     *  and updates local balances of seller or buyer, respectively.
     * @dev Can be executed by anyone, but the operator signature must be included as input param.
     *  Seller or Buyer's local balances are updated, allowing explicit withdrawal.
     *  Moves payment to PAID or REFUNDED state on transfer success/failure, respectively.
     * @param transferResult The asset transfer result struct signed by the operator.
     * @param operatorSignature The operator signature of transferResult
     */
    function finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external;

    /**
     * @notice Relays the operator signature declaring that the asset transfer was successful or failed,
     *  updates balances of seller or buyer, respectively, and proceeds to withdraw all funds 
     *  in this contract available to the rightful recipient of the paymentId: 
     *  the seller if transferResult.wasSuccessful == true, the buyer otherwise.
     * @dev If recipient has set onlyUserCanWithdraw == true, then msg.sender must be the recipient;
     *  otherwise, anyone can execute this method, with funds arriving to the recipient too, but with a
     *  helping 3rd party covering gas costs and TX sending hassle.
     *  The operator signature must be included as input param.
     *  Moves payment to PAID or REFUNDED state on transfer success/failure, respectively.
     * @param transferResult The asset transfer result struct signed by the operator.
     * @param operatorSignature The operator signature of transferResult
     */
    function finalizeAndWithdraw(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external;

    /**
     * @notice Moves buyer's provided funds to buyer's balance.
     * @dev Anybody can call this function.
     *  Requires acceptsRefunds == true to proceed.
     *  After updating buyer's balance, he/she can later withdraw.
     *  Moves payment to REFUNDED state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function refund(bytes32 paymentId) external;

    /**
     * @notice Executes refund and withdraw to the buyer in one transaction.
     * @dev If the buyer has set onlyUserCanWithdraw == true, then msg.sender must be the recipient;
     *  otherwise, anyone can execute this method, with funds arriving to the buyer too, but with a
     *  helping 3rd party covering gas costs and TX sending hassle.
     *  Requires acceptsRefunds == true to proceed.
     *  All of msg.sender's balance in the contract is withdrawn,
     *  not only the part that was locked in this particular paymentId
     *  Moves payment to REFUNDED state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function refundAndWithdraw(bytes32 paymentId) external;

    /**
     * @notice Transfers funds avaliable in this
     *  contract's balanceOf[msg.sender] to msg.sender
     */
    function withdraw() external;

    /**
     * @notice Transfers funds avaliable in this
     *  contract's balanceOf[recipient] to recipient.
     *  The funds still go to straight the recipient, as if he/she
     *  has executed the withdrawal() method, but the msg.sender
     *  covers gas costs and the hassle of executing the transaction.
     *  Users can always opt out from this feature, using the setOnlyUserCanWithdraw method.
     */
    function relayedWithdraw(address recipient) external;

    /**
     * @notice Transfers only the specified amount
     *  from this contract's balanceOf[msg.sender] to msg.sender.
     *  Reverts if balanceOf[msg.sender] < amount.
     * @param amount The required amount to withdraw
     */
    function withdrawAmount(uint256 amount) external;

    // VIEW FUNCTIONS

    /**
     * @notice Returns whether sellers need to be registered to be able to accept payments
     * @return Returns true if sellers need to be registered to be able to accept payments
     */
    function isSellerRegistrationRequired() external view returns (bool);

    /**
     * @notice Returns true if the address provided is a registered seller
     * @param addr the address that is queried
     * @return Returns whether the address is registered as seller
     */
    function isRegisteredSeller(address addr) external view returns (bool);

    /**
     * @notice Returns the local balance of the provided address that is stored in this
     *  contract, and hence, available for withdrawal.
     * @param addr the address that is queried
     * @return the local balance
     */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * @notice Returns all data stored in a payment
     * @param paymentId The unique ID that identifies the payment.
     * @return the struct stored for the payment
     */
    function paymentInfo(bytes32 paymentId)
        external
        view
        returns (Payment memory);

    /**
     * @notice Returns the state of a payment.
     * @dev If payment is in ASSET_TRANSFERRING, it may be worth
     *  checking acceptsRefunds to check if it has gone beyond expirationTime.
     * @param paymentId The unique ID that identifies the payment.
     * @return the state of the payment.
     */
    function paymentState(bytes32 paymentId) external view returns (State);

    /**
     * @notice Returns true if the payment accepts a refund to the buyer
     * @dev The payment must be in ASSET_TRANSFERRING and beyond expirationTime.
     * @param paymentId The unique ID that identifies the payment.
     * @return true if the payment accepts a refund to the buyer.
     */
    function acceptsRefunds(bytes32 paymentId) external view returns (bool);

    /**
     * @notice Returns the address of the of the contract containing
     *  the implementation of the EIP712 verifying functions
     * @return the address of the EIP712 verifier contract
     */
    function EIP712Address() external view returns (address);

    /**
     * @notice Returns the amount of seconds that a payment
     *  can remain in ASSET_TRANSFERRING state without positive
     *  or negative confirmation by the operator
     * @return the payment window in secs
     */
    function paymentWindow() external view returns (uint256);

    /**
     * @notice Returns the max fee (in BPS units) that can be accepted in any payment
     *  despite operator and buyer having signed a larger amount;
     *  a value of 10000 BPS would correspond to 100% (no limit at all)
     * @return the max fee (in BPS units)
     */
    function maxFeeBPS() external view returns (uint256);

    /**
     * @notice Returns a descriptor about the currency that this contract accepts
     * @return the string describing the currency
     */
    function currencyLongDescriptor() external view returns (string memory);

    /**
     * @notice Splits the funds required to provide 'amount' into two sources:
     *  - externalFunds: the funds required to be transferred from the external buyer balance
     *  - localFunds: the funds required from the buyer's already available balance in this contract.
     * @param buyer The address for which the amount is to be split
     * @param amount The amount to be split
     * @return externalFunds The funds required to be transferred from the external buyer balance
     * @return localFunds The amount of local funds that will be used.
     */
    function splitFundingSources(address buyer, uint256 amount)
        external
        view
        returns (uint256 externalFunds, uint256 localFunds);

    /**
     * @notice Returns true if the 'amount' required for a payment is available to this contract.
     * @dev In more detail: returns true if the sum of the buyer's local balance in this contract,
     *  plus the external available balance, is larger or equal than 'amount'
     * @param buyer The address for which funds are queried
     * @param amount The amount that is queried
     * @return Returns true if enough funds are available
     */
    function enoughFundsAvailable(address buyer, uint256 amount)
        external
        view
        returns (bool);

    /**
     * @notice Returns the maximum amount of funds available to a buyer
     * @dev In more detail: returns the sum of the buyer's local balance in this contract,
     *  plus the available external balance.
     * @param buyer The address for which funds are queried
     * @return the max funds available
     */
    function maxFundsAvailable(address buyer) external view returns (uint256);

    /**
     * @notice Reverts unless the requirements for a BuyNowInput are fulfilled.
     * @param buyNowInp The BuyNowInput struct
     */
    function assertBuyNowInputsOK(BuyNowInput calldata buyNowInp) external view;

    /**
     * @notice Returns the value of onlyUserCanWithdraw for a given user
     * @param user The address of the user
     */
    function onlyUserCanWithdraw(address user) external view returns (bool);

    // PURE FUNCTIONS

    /**
     * @notice Safe computation of fee amount for a provided amount, feeBPS pair
     * @dev Must return a value that is guaranteed to be less or equal to the provided amount
     * @param amount The amount
     * @param feeBPS The percentage fee expressed in Basis Points (bps).
     *  feeBPS examples:  2.5% = 250 bps, 10% = 1000 bps, 100% = 10000 bps
     * @return The fee amount
     */
    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        external
        pure
        returns (uint256);
}