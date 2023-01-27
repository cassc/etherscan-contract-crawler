// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;

import "AccessControlUpgradeable.sol";
import "Initializable.sol";

/**
 * @title PreSend Affiliate Contract
 * @dev Upgradeable affiliate contract that is integrated with the PreSend verification system and payment smart contract
 */
contract PreSendAffiliate is Initializable, AccessControlUpgradeable {
    // Addresses with this role can update affiliate balances and deposit amounts.
    bytes32 public constant AFFILIATE_ADMIN = keccak256("AFFILIATE_ADMIN");

    // Role for the payment smart contract.
    bytes32 public constant PAYMENT_CONTRACT = keccak256("PAYMENT_CONTRACT");

    // Mapping to determine the block timestamp for when an affiliate registered.
    mapping(address => uint256) public affiliateToRegisteredTimestamp;

    // Mapping to determine the claimable balance for each affiliate.
    mapping(address => uint256) public affiliateToClaimableAmount;

    // Mapping to determine the total amount raised by an affiliate.
    mapping(address => uint256) public affiliateToTotalRaised;

    // The address of the PreSend payments smart contract.
    address public paymentsAddress;

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
    function initialize(address _paymentsAddress) initializer external {
        require(_paymentsAddress != address(0), "PreSend Payments address can't be the 0 address.");

        paymentsAddress = _paymentsAddress;
        _setupRole(PAYMENT_CONTRACT, paymentsAddress);
        _setupRole(AFFILIATE_ADMIN, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit paymentContractAddressUpdated(_paymentsAddress);
    }

    /**
    @dev Function for affiliates to claim their cut of their affiliate partners paying for PreSend transfers.
    */
    function affiliateClaim() external {
        address affiliate = msg.sender;

        uint256 affiliateClaimAmount = affiliateToClaimableAmount[affiliate];
        affiliateToClaimableAmount[affiliate] = 0;
        (bool success, ) = affiliate.call{value: affiliateClaimAmount}("");
        require(success, "Failed to claim your affiliate balance!");

        emit affiliateClaimed(msg.sender, affiliateClaimAmount);
    }

    /**
    @dev Function to add an affiliate - anyone can call this to make themselves an affiliate at 5% (percentage determined off-chain)
    @param affiliate the address of the affiliate
    */
    function addAffiliate(address affiliate) external {
        require(affiliate != address(0), "Affiliate address cannot be the zero address.");
        affiliateToRegisteredTimestamp[affiliate] = block.timestamp;

        emit affiliateAdded(affiliate);
    }

    /** 
    @dev Function for the payment smart contract to invoke whenever someone pays a fee and part of it goes to an affiliate.
    @param affiliate the address of the affiliate receiving funds
    @param amount the amount of the native coin going to the affiliate
    */
    function increaseAffiliateAmount(address affiliate, uint256 amount) external onlyRole(PAYMENT_CONTRACT) {
        require(affiliate != address(0), "Affiliate address cannot be the zero address.");
        affiliateToClaimableAmount[affiliate] += amount;
        affiliateToTotalRaised[affiliate] += amount;
        emit affiliateAmountIncreased(affiliate, amount);
    }

    /** 
    @dev Function for the payment smart contract to decrease the next deposit amount for an affiliate.
    @param affiliate the address of the affiliate funds are being decreased for
    @param amount the amount of the native coin to remove from an affiliate's next deposit
    */
    function decreaseAffiliateAmount(address affiliate, uint256 amount) external onlyRole(PAYMENT_CONTRACT) {
        require(affiliate != address(0), "Affiliate address cannot be the zero address.");
        affiliateToClaimableAmount[affiliate] -= amount;
        affiliateToTotalRaised[affiliate] -= amount;
        emit affiliateAmountDecreased(affiliate, amount);
    }

    /**
    @dev Affiliate admin only function to update the payment smart contract address.
    @param newPaymentAddress the new payment address
    */
    function updatePaymentAddress(address newPaymentAddress) external onlyRole(AFFILIATE_ADMIN) {
        require(newPaymentAddress != address(0), "PreSend Payments address can't be the 0 address.");
        
        _revokeRole(PAYMENT_CONTRACT, paymentsAddress);
        _grantRole(PAYMENT_CONTRACT, newPaymentAddress);
        paymentsAddress = newPaymentAddress;

        emit paymentContractAddressUpdated(newPaymentAddress);
    }

    /**
    @dev Affiliate admin only function to extract affiliate funds in case of an emergency (i.e. an affiliate needs their funds but can't claim for some reason).
    * this function will take away affiliate funds and should only be used for very specific cases such as an affiliate losing access to their wallet
    @param amount the amount of the native coin to withdraw from the contract
    @param useAmount boolean to determine if the amount should be used. If false, just extract all funds from the contract.
    */
    function extractFees(uint256 amount, bool useAmount) external onlyRole(AFFILIATE_ADMIN) {
        uint256 amountToExtract = address(this).balance;

        if (useAmount) {
            amountToExtract = amount;
        }

        (bool success, ) = msg.sender.call{value: amountToExtract}("");
        require(success, "Failed to send native coin to affiliate admin");
    }

    /**
    @dev Only owner function to change the affiliate admin for depositing funds. This is the role given to the address the Chainlink keeper uses.
    @param newAdmin address of the user to make an affiliate admin
    @param oldAdmin address of the user to remove from the affiliate admin role
    */
    function changeAffiliateAdmin(address newAdmin, address oldAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "New admin address cannot be the zero address.");
        require(oldAdmin != address(0), "Old admin address cannot be the zero address.");
        _grantRole(AFFILIATE_ADMIN, newAdmin);
        _revokeRole(AFFILIATE_ADMIN, oldAdmin);
    }
    /**
    @dev Only owner function to change the payment contract admin in case any of the payment functions need to be called manually (such as increaseAffiliateAmount).
    @param newAdmin address of the user to make a payment admin
    @param oldAdmin address of the user to remove from the payment admin role
    */
    function changePaymentAdmin(address newAdmin, address oldAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "New admin address cannot be the zero address.");
        require(oldAdmin != address(0), "Old admin address cannot be the zero address.");
        _grantRole(PAYMENT_CONTRACT, newAdmin);
        _revokeRole(PAYMENT_CONTRACT, oldAdmin);
    }

    receive() external payable {}

    uint256[49] private __gap;
}