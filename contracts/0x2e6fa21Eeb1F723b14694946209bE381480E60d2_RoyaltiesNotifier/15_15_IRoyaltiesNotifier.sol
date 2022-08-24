pragma solidity ^0.8.14;

import "IAccessControlUpgradeable.sol";

interface IRoyaltiesNotifier is IAccessControlUpgradeable {
    event PaymentReceived(address indexed payer, uint256 amount);
    event PaymentWithdrawn(address indexed payee, uint256 amount);

    function setPaymentReceiver(address payable paymentReceiver_) external;

    function withdrawAllBalance() external;
}