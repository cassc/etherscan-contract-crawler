pragma solidity ^0.8.14;

import "AccessControlUpgradeable.sol";
import "AddressUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "IRoyaltiesNotifier.sol";

/**
    @title Voice Royalties Notifier
    @notice forwards royalty payouts to the Voice API and logs received amounts
    @author Evgenii Tsvigun [email protected]
  */
contract RoyaltiesNotifier is IRoyaltiesNotifier, AccessControlUpgradeable, UUPSUpgradeable {

    address payable paymentReceiver;

    receive() external payable {
        acceptPayment(msg.sender, msg.value);
    }

    fallback() external payable {
        acceptPayment(msg.sender, msg.value);
    }

    /**
     * @notice addresses with DEFAULT_ADMIN_ROLE assigned are able set payment receiver address
     */
    function setPaymentReceiver(address payable paymentReceiver_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentReceiver = paymentReceiver_;
    }

    /**
     * @notice Initializes the contract by setting the payment receiver and assigning DEFAULT_ADMIN_ROLE to the sender
     */
    function initialize(
        address payable paymentReceiver_
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        paymentReceiver = paymentReceiver_;
    }

    /**
     * @notice addresses with DEFAULT_ADMIN_ROLE assigned are able to perform upgrades
     */
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev log payment received, forward the no validation of payment receiver to keep transactions cheap
     */
    function acceptPayment(address payer, uint256 amount) private {
        emit PaymentReceived(payer, amount);
    }

    function withdrawAllBalance() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        emit PaymentWithdrawn(paymentReceiver, amount);
        AddressUpgradeable.sendValue(paymentReceiver, amount);
    }
}