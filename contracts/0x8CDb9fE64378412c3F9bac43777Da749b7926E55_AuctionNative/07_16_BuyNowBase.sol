// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./IBuyNowBase.sol";
import "../../roles/Operators.sol";
import "../../roles/FeesCollectors.sol";
import "./IEIP712VerifierBuyNow.sol";

/**
 * @title Base Escrow Contract for Payments in BuyNow mode.
 * @author Freeverse.io, www.freeverse.io
 * @notice Full contract documentation in IBuyNowBase
 */

abstract contract BuyNowBase is IBuyNowBase, FeesCollectors, Operators {
    // the address of the deployed EIP712 verifier contract
    address internal _eip712;

    // a human readable long descripton of the accepted currency 
    // (be it native or ERC20), e.g. "USDC on Polygon PoS"
    string private _currencyLongDescriptor;

    //  the amount of seconds that a payment can remain
    //  in ASSET_TRANSFERRING state without positive
    //  or negative confirmation by the operator
    uint256 internal _paymentWindow;

    //  the max fee (in BPS units) that can be accepted in any payment
    //  despite operator and buyer having signed a larger amount;
    //  a value of 10000 BPS would correspond to 100% (no limit at all)
    uint256 internal _maxFeeBPS;

    // whether sellers need to be registered to be able to accept payments
    bool internal _isSellerRegistrationRequired;

    // mapping from seller address to whether seller is registered
    mapping(address => bool) internal _isRegisteredSeller;

    // mapping from user address to a bool:
    // - if true: only the user can execute withdrawals of his/her local balance
    // - if false: any address can help and execute the withdrawals on behalf of the user
    //   (the funds still go straight to the user, but the helper address covers gas costs
    //    and the hassle of executing the transaction)
    mapping(address => bool) internal _onlyUserCanWithdraw;

    // mapping from paymentId to payment struct describing the entire payment process
    mapping(bytes32 => Payment) internal _payments;

    // mapping from user address to local balance in this contract
    mapping(address => uint256) internal _balanceOf;

    constructor(string memory currencyDescriptor, address eip712) {
        setEIP712(eip712);
        _currencyLongDescriptor = currencyDescriptor;
        setPaymentWindow(30 days);
        _isSellerRegistrationRequired = false;
        setMaxFeeBPS(3000); // 30%
    }

    /**
     * @notice Sets the address of the EIP712 verifier contract.
     * @dev This upgradable pattern is required in case that the
     *  EIP712 spec/code changes in the future
     * @param eip712address The address of the new EIP712 contract.
     */
    function setEIP712(address eip712address) public onlyOwner {
        emit EIP712(eip712address, _eip712);
        _eip712 = eip712address;
    }

    /**
     * @notice Sets the amount of time available to the operator, after the payment starts,
     *  to confirm either the success or the failure of the asset transfer.
     *  After this time, the payment moves to FAILED, allowing buyer to withdraw.
     * @param window The amount of time available, in seconds.
     */
    function setPaymentWindow(uint256 window) public onlyOwner {
        require(
            (window < 60 days) && (window > 3 hours),
            "BuyNowBase::setPaymentWindow: payment window outside limits"
        );
        emit PaymentWindow(window, _paymentWindow);
        _paymentWindow = window;
    }

    /**
     * @notice Sets the max fee (in BPS units) that can be accepted in any payment
     *  despite operator and buyer having signed a larger amount;
     *  a value of 10000 BPS would correspond to 100% (no limit at all)
     * @param feeBPS The new max fee (in BPS units)
     */
    function setMaxFeeBPS(uint256 feeBPS) public onlyOwner {
        require(
            (feeBPS <= 10000) && (feeBPS >= 0),
            "BuyNowBase::setMaxFeeBPS: maxFeeBPS outside limits"
        );
        emit MaxFeeBPS(feeBPS, _maxFeeBPS);
        _maxFeeBPS = feeBPS;
    }

    /**
     * @notice Sets whether sellers are required to register in this contract before being
     *  able to accept payments.
     * @param isRequired (bool) if true, registration is required.
     */
    function setIsSellerRegistrationRequired(bool isRequired)
        external
        onlyOwner
    {
        _isSellerRegistrationRequired = isRequired;
    }

    /// @inheritdoc IBuyNowBase
    function registerAsSeller() external {
        require(
            !_isRegisteredSeller[msg.sender],
            "BuyNowBase::registerAsSeller: seller already registered"
        );
        _isRegisteredSeller[msg.sender] = true;
        emit NewSeller(msg.sender);
    }

    /// @inheritdoc IBuyNowBase
    function setOnlyUserCanWithdraw(bool onlyUserCan) external {
        emit OnlyUserCanWithdraw(msg.sender, onlyUserCan, _onlyUserCanWithdraw[msg.sender]);
        _onlyUserCanWithdraw[msg.sender] = onlyUserCan;
    }

    /// @inheritdoc IBuyNowBase
    function finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external {
        _finalize(transferResult, operatorSignature);
    }

    /// @inheritdoc IBuyNowBase
    function finalizeAndWithdraw(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external {
        address recipient = transferResult.wasSuccessful
            ? _payments[transferResult.paymentId].seller
            : _payments[transferResult.paymentId].buyer;
        if (_onlyUserCanWithdraw[recipient]) require(
            msg.sender == recipient,
            "BuyNowBase::finalizeAndWithdraw: tx sender not authorized to withdraw on recipients behalf"
        );
        _finalize(transferResult, operatorSignature);
        // withdrawal cannot fail due to zero balance, since
        // balance has just been increased when finalizing the payment:
        _withdrawAmount(recipient, _balanceOf[recipient]);
    }

    /// @inheritdoc IBuyNowBase
    function refund(bytes32 paymentId) public {
        _refund(paymentId);
    }

    /// @inheritdoc IBuyNowBase
    function refundAndWithdraw(bytes32 paymentId) external {
        address recipient = _payments[paymentId].buyer;
        if (_onlyUserCanWithdraw[recipient]) require(
            msg.sender == recipient,
            "BuyNowBase::refundAndWithdraw: tx sender not authorized to withdraw on recipients behalf"
        );
        _refund(paymentId);
        // withdrawal cannot fail due to zero balance, since
        // balance has just been increased when refunding:
        _withdrawAmount(recipient, _balanceOf[recipient]);
    }

    /// @inheritdoc IBuyNowBase
    function withdraw() external {
        _withdraw();
    }

    /// @inheritdoc IBuyNowBase
    function relayedWithdraw(address recipient) external {
        require(
            !_onlyUserCanWithdraw[recipient] || (msg.sender == recipient),
            "BuyNowBase::relayedWithdraw: tx sender not authorized to withdraw on recipients behalf"
        );
        _withdrawAmount(recipient, _balanceOf[recipient]);
    }

    /// @inheritdoc IBuyNowBase
    function withdrawAmount(uint256 amount) external {
        _withdrawAmount(msg.sender, amount);
    }

    // PRIVATE & INTERNAL FUNCTIONS

    /**
     * @dev Interface to method that must update buyer's local balance on arrival of a payment,
     *  re-using local balance if available. In ERC20 payments, it transfers to this contract
     *  the required amount; in case of native crypto, it must add excess of provided funds, if any, to local balance.
     * @param buyer The address of the buyer
     * @param newFundsNeeded The elsewhere computed minimum amount of funds required to be provided by the buyer,
     *  having possible re-use of local funds into account
     * @param localFunds The elsewhere computed amount of funds available to the buyer in this contract, that will be
     *  re-used in the payment
     */
    function _updateBuyerBalanceOnPaymentReceived(
        address buyer,
        uint256 newFundsNeeded,
        uint256 localFunds
    ) internal virtual;

    /**
     * @dev Asserts correcteness of buyNow input parameters,
     *  transfers required funds from external contract (in case of ERC20 Payments),
     *  reuses buyer's local balance (if any),
     *  and stores the payment data in contract's storage.
     *  Moves the payment to AssetTransferring state
     * @param buyNowInp The BuyNowInput struct
     * @param operator The address of the operator of this payment.
     */
    function _processBuyNow(
        BuyNowInput calldata buyNowInp,
        address operator,
        bytes calldata sellerSignature
    ) internal {
        require(
            IEIP712VerifierBuyNow(_eip712).verifySellerSignature(
                sellerSignature,
                buyNowInp
            ),
            "BuyNowBase::_processBuyNow: incorrect seller signature"
        );
        assertBuyNowInputsOK(buyNowInp);
        assertSeparateRoles(operator, buyNowInp.buyer, buyNowInp.seller);
        (uint256 newFundsNeeded, uint256 localFunds) = splitFundingSources(
            buyNowInp.buyer,
            buyNowInp.amount
        );
        _updateBuyerBalanceOnPaymentReceived(buyNowInp.buyer, newFundsNeeded, localFunds);
        _payments[buyNowInp.paymentId] = Payment(
            State.AssetTransferring,
            buyNowInp.buyer,
            buyNowInp.seller,
            buyNowInp.universeId,
            universeFeesCollector(buyNowInp.universeId),
            block.timestamp + _paymentWindow,
            buyNowInp.feeBPS,
            buyNowInp.amount
        );
        emit BuyNow(buyNowInp.paymentId, buyNowInp.buyer, buyNowInp.seller);
    }

    /**
     * @dev (private) Moves the payment funds to the buyer's local balance
     *  The buyer still needs to withdraw afterwards.
     *  Moves the payment to REFUNDED state
     * @param paymentId The unique ID that identifies the payment.
     */
    function _refund(bytes32 paymentId) private {
        require(
            acceptsRefunds(paymentId),
            "BuyNowBase::_refund: payment does not accept refunds at this stage"
        );
        _refundToLocalBalance(paymentId);
    }

    /**
     * @dev (private) Uses the operator signed msg regarding asset transfer success to update
     *  the balances of seller (on success) or buyer (on failure).
     *  They still need to withdraw afterwards.
     *  Moves the payment to either PAID (on success) or REFUNDED (on failure) state
     * @param transferResult The asset transferResult struct signed by the operator.
     * @param operatorSignature The operator signature of transferResult
     */
    function _finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) private {
        Payment memory payment = _payments[transferResult.paymentId];
        require(
            paymentState(transferResult.paymentId) == State.AssetTransferring,
            "BuyNowBase::_finalize: payment not initially in asset transferring state"
        );
        require(
            IEIP712VerifierBuyNow(_eip712).verifyAssetTransferResult(
                transferResult,
                operatorSignature,
                universeOperator(payment.universeId)
            ),
            "BuyNowBase::_finalize: only the operator can sign an assetTransferResult"
        );
        if (transferResult.wasSuccessful) {
            _finalizeSuccess(transferResult.paymentId, payment);
        } else {
            _finalizeFailed(transferResult.paymentId);
        }
    }

    /**
     * @dev (private) Updates the balance of the seller on successful asset transfer
     *  Moves the payment to PAID
     * @param paymentId The unique ID that identifies the payment.
     * @param payment The payment struct corresponding to paymentId
     */
    function _finalizeSuccess(bytes32 paymentId, Payment memory payment) private {
        _payments[paymentId].state = State.Paid;
        uint256 feeAmount = computeFeeAmount(payment.amount, payment.feeBPS);
        _balanceOf[payment.seller] += (payment.amount - feeAmount);
        _balanceOf[payment.feesCollector] += feeAmount;
        emit Paid(paymentId);
    }

    /**
     * @dev (private) Updates the balance of the buyer on failed asset transfer
     *  Moves the payment to REFUNDED
     * @param paymentId The unique ID that identifies the payment.
     */
    function _finalizeFailed(bytes32 paymentId) private {
        _refundToLocalBalance(paymentId);
    }

    /**
     * @dev (private) Executes refund, moves to REFUNDED state
     * @param paymentId The unique ID that identifies the payment.
     */
    function _refundToLocalBalance(bytes32 paymentId) private {
        _payments[paymentId].state = State.Refunded;
        Payment memory payment = _payments[paymentId];
        _balanceOf[payment.buyer] += payment.amount;
        emit BuyerRefunded(paymentId, payment.buyer);
    }

    /**
     * @dev (private) Transfers funds available in this
     *  contract's balanceOf[msg.sender] to msg.sender
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     */
    function _withdraw() private {
        _withdrawAmount(msg.sender, _balanceOf[msg.sender]);
    }

    /**
     * @dev (private) Transfers the specified amount of 
     *  funds in this contract's balanceOf[recipient] to the recipient address.
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     * @param recipient The address of to transfer funds from the local contract
     * @param amount The amount to withdraw.
    */
    function _withdrawAmount(address recipient, uint256 amount) private {
        // requirements: 
        //  1. check that there is enough balance
        uint256 currentBalance = _balanceOf[recipient];
        require(
            currentBalance >= amount,
            "BuyNowBase::_withdrawAmount: not enough balance to withdraw specified amount"
        );
        //  2. prevent dummy withdrawals with 0 amount to avoid useless events 
        require(
            amount > 0,
            "BuyNowBase::_withdrawAmount: cannot withdraw zero amount"
        );
        // effect:
        _balanceOf[recipient] = currentBalance - amount;
        // interaction:
        _transfer(recipient, amount);
        emit Withdraw(recipient, amount);
    }

    /**
     * @dev Interface to method that transfers the specified amount to the specified address.
     *  Requirements and effects are checked before calling this function.
     *  Implementations can deal with native crypto transfers, with ERC20 token transfers, etc.
     * @param to The address that must receive the funds.
     * @param amount The amount to transfer.
    */
    function _transfer(address to, uint256 amount) internal virtual;

    // VIEW FUNCTIONS

    /// @inheritdoc IBuyNowBase
    function isSellerRegistrationRequired() external view returns (bool) {
        return _isSellerRegistrationRequired;
    }

    /// @inheritdoc IBuyNowBase
    function isRegisteredSeller(address addr) external view returns (bool) {
        return _isRegisteredSeller[addr];
    }

    /// @inheritdoc IBuyNowBase
    function balanceOf(address addr) external view returns (uint256) {
        return _balanceOf[addr];
    }

    /// @inheritdoc IBuyNowBase
    function paymentInfo(bytes32 paymentId)
        external
        view
        returns (Payment memory)
    {
        return _payments[paymentId];
    }

    /// @inheritdoc IBuyNowBase
    function paymentState(bytes32 paymentId) public view virtual returns (State) {
        return _payments[paymentId].state;
    }

    /// @inheritdoc IBuyNowBase
    function acceptsRefunds(bytes32 paymentId) public view returns (bool) {
        return
            (paymentState(paymentId) == State.AssetTransferring) &&
            (block.timestamp > _payments[paymentId].expirationTime);
    }

    /// @inheritdoc IBuyNowBase
    function EIP712Address() external view returns (address) {
        return _eip712;
    }

    /// @inheritdoc IBuyNowBase
    function paymentWindow() external view returns (uint256) {
        return _paymentWindow;
    }

    /// @inheritdoc IBuyNowBase
    function maxFeeBPS() external view returns (uint256) {
        return _maxFeeBPS;
    }

    /// @inheritdoc IBuyNowBase
    function currencyLongDescriptor() external view returns (string memory) {
        return _currencyLongDescriptor;
    }

    /// @inheritdoc IBuyNowBase
    function assertBuyNowInputsOK(BuyNowInput calldata buyNowInp) public view {
        require(
            buyNowInp.amount > 0,
            "BuyNowBase::assertBuyNowInputsOK: payment amount cannot be zero"
        );
        require(
            buyNowInp.feeBPS <= _maxFeeBPS,
            "BuyNowBase::assertBuyNowInputsOK: fee cannot be larger than maxFeeBPS"
        );
        require(
            paymentState(buyNowInp.paymentId) == State.NotStarted,
            "BuyNowBase::assertBuyNowInputsOK: payment in incorrect current state"
        );
        require(
            block.timestamp <= buyNowInp.deadline,
            "BuyNowBase::assertBuyNowInputsOK: payment deadline expired"
        );
        if (_isSellerRegistrationRequired)
            require(
                _isRegisteredSeller[buyNowInp.seller],
                "BuyNowBase::assertBuyNowInputsOK: seller not registered"
            );
    }

    /// @inheritdoc IBuyNowBase
    function enoughFundsAvailable(address buyer, uint256 amount)
        public
        view
        returns (bool)
    {
        return maxFundsAvailable(buyer) >= amount;
    }

    /// @inheritdoc IBuyNowBase
    function maxFundsAvailable(address buyer) public view returns (uint256) {
        return _balanceOf[buyer] + externalBalance(buyer);
    }

    /**
     * @notice Interface to method that must return the amount available to a buyer outside this contract
     * @dev If the contract that implements this interface deals with native crypto, then it must return buyer.balance;
     *  if dealing with ERC20, it must return the available balance in the external ERC20 contract.
     * @param buyer The address for which funds are queried
     * @return the external funds available
     */
    function externalBalance(address buyer) public view virtual returns (uint256);

    /// @inheritdoc IBuyNowBase
    function splitFundingSources(address buyer, uint256 amount)
        public
        view
        returns (uint256 externalFunds, uint256 localFunds)
    {
        uint256 localBalance = _balanceOf[buyer];
        localFunds = (amount > localBalance) ? localBalance : amount;
        externalFunds = (amount > localBalance) ? amount - localBalance : 0;
    }

    /// @inheritdoc IBuyNowBase
    function onlyUserCanWithdraw(address user) public view returns (bool) {
        return _onlyUserCanWithdraw[user];
    }

    // PURE FUNCTIONS

    /**
     * @dev Reverts if either of the following addresses coincide: operator, buyer, seller
     *  On the one hand, the operator must be an observer.
     *  On the other hand, the seller cannot act on his/her already owned assets.
     * @param operator The address of the operator
     * @param buyer The address of the buyer
     * @param seller The address of the seller
    */
    function assertSeparateRoles(address operator, address buyer, address seller)
        internal pure {
        require(
            (operator != buyer) && (operator != seller),
            "BuyNowBase::assertSeparateRoles: operator must be an observer"
        );
        require(
            (buyer != seller),
            "BuyNowBase::assertSeparateRoles: buyer and seller cannot coincide"
        );
    }

    /// @inheritdoc IBuyNowBase
    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        public
        pure
        returns (uint256)
    {
        uint256 feeAmount = (amount * feeBPS) / 10000;
        return (feeAmount <= amount) ? feeAmount : amount;
    }
}