// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;

/**
 * @title PreSend Affiliate Contract Interface
 */
interface IPreSendAffiliate {
    // Addresses with this role can update affiliate balances and deposit amounts.
    function AFFILIATE_ADMIN() external view returns (bytes32);

    // Role for the payment smart contract.
    function PAYMENT_CONTRACT() external view returns (bytes32);

    // Mapping to determine the block timestamp for when an affiliate registered.
    function affiliateToRegisteredTimestamp(address affiliate) external view returns (uint256);

    // Mapping to determine the claimable balance for each affiliate.
    function affiliateToClaimableAmount(address affiliate) external view returns (uint256);

    // Mapping to determine the total amount raised by an affiliate.
    function affiliateToTotalRaised(address affiliate) external view returns (uint256);

    // The address of the PreSend payments smart contract.
    function paymentsAddress() external view returns (address);

    // Event to emit whenever an affiliate claims.
    event affiliateClaimed(address indexed affiliate, uint256 amount);

    // Event to emit whenever the amount an affiliate can claim is increased.
    event affiliateAmountIncreased(address indexed affiliate, uint256 amountIncreasedBy);

    // Event to emit whenever the amount an affiliate can claim is decreased.
    event affiliateAmountDecreased(address indexed affiliate, uint256 amountDecreasedBy);

    // Event to emit whenever the PreSend Payment contract address is updated.
    event paymentContractAddressUpdated(address indexed newPaymentContractAddress);

    // Event to emit whenever an affiliate is added.
    event affiliateAdded(address indexed affiliate);

    /**
    @dev Initializer function that sets the address of the payments contract. Used in place of constructor since this is an upgradeable contract.
    @param _paymentsAddress the address of the PreSend payments contract
    */
    function initialize(address _paymentsAddress) external;

    /**
    @dev Function for affiliates to claim their cut of their affiliate partners paying for PreSend transfers.
    */
    function affiliateClaim() external;

    /**
    @dev Function to add an affiliate at 5% - anyone can call this to make themselves an affiliate at 5%
    @param affiliate the address of the affiliate
    */
    function addAffiliate(address affiliate) external;

    /** 
    @dev Function for the payment smart contract to invoke whenever someone pays a fee and part of it goes to an affiliate.
    @param affiliate the address of the affiliate receiving funds
    @param amount the amount of the native coin going to the affiliate
    */
    function increaseAffiliateAmount(address affiliate, uint256 amount) external;

    /** 
    @dev Function for the payment smart contract to decrease the next deposit amount for an affiliate.
    @param affiliate the address of the affiliate funds are being decreased for
    @param amount the amount of the native coin to remove from an affiliate's next deposit
    */
    function decreaseAffiliateAmount(address affiliate, uint256 amount) external;

    /**
    @dev Affiliate admin only function to update the payment smart contract address.
    @param newPaymentAddress the new payment address
    */
    function updatePaymentAddress(address newPaymentAddress) external;

    /**
    @dev Only owner function to change the affiliate admin for depositing funds. This is the role given to the address the Chainlink keeper uses.
    @param newAdmin address of the user to make an affiliate admin
    @param oldAdmin address of the user to remove from the affiliate admin role
    */
    function changeAffiliateAdmin(address newAdmin, address oldAdmin) external;

    /**
    @dev Only owner function to change the payment contract admin in case any of the payment functions need to be called manually (such as increaseAffiliateAmount).
    @param newAdmin address of the user to make a payment admin
    @param oldAdmin address of the user to remove from the payment admin role
    */
    function changePaymentAdmin(address newAdmin, address oldAdmin) external;

    receive() external payable;
}