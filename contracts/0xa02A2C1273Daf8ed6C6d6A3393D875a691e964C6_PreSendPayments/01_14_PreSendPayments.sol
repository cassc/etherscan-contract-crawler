// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;

import "AccessControlUpgradeable.sol";
import "Initializable.sol";
import "AutomationCompatible.sol";
import "AggregatorV3Interface.sol";

import "IPreSendAffiliate.sol";

/**
 * @title Upgradeable PreSend Payments Smart Contract
 * @dev Payment contract that is integrated with the PreSend verification system and Affiliate smart contract
 */
contract PreSendPayments is AutomationCompatibleInterface, Initializable, AccessControlUpgradeable  {
    // Addresses with this role can update user payment information.
    bytes32 public constant PAYMENT_ADMIN = keccak256("PAYMENT_ADMIN");

    // Addresses with this role can extract token fees.
    bytes32 public constant FEE_ADMIN = keccak256("FEE_ADMIN");

    // Mapping to determine how much each address can transfer with PreSend services for each token address.
    // mapping (address (user address) => mapping(address (token address) => uint256 (currency amount fees have been paid for)))
    mapping (address => mapping(address => uint256)) public addressToApprovedAmount;

    // Mapping to determine how much of the fees from this contract can be attributed to each affiliate.
    // This mapping is here instead of the PreSendAffiliate contract since it's dividing the funds stored here by affiliate.
    mapping (address => uint256) public affiliateToPreSendRevenue;

    // Total gross revenue - accounts for all funds that come into this contract.
    uint256 public grossRevenue;

    // Net revenue - fee funds minus what is sent to affiliates.
    uint256 public netRevenue;

    // Affiliate smart contract reference.
    IPreSendAffiliate public preSendAffiliate;

    // Address of the treasury where affiliate payments will go.
    address public treasuryAddress;

    // The divisor to charge a certain percentage of the total currency being transferred as a part of the fee.
    uint256 public feeDivisor;

    // Aggregator to get the price of the native coin in USD.
    // Example - 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0 for Matic / USD
    AggregatorV3Interface public aggregator;

    // The interval for sending payment fees to the treasury address with the Chainlink Keeper
    uint256 public sendPaymentFeesInterval;

    // The timestamp for the last time payment fees were sent to the treasury address with the Chainlink Keeper
    uint256 public lastPaymentFeeSendTimeStamp;

    // Number of seconds an affiliate registration lasts for before they need to reregister to get fees again.
    uint256 public affiliateRegistrationTime;

    // Why 10 ** 26? - 10 ** 18 to convert to wei, divide by 100 since it's 2 cents, and then multiple by 10**8 since the aggregator returns the coin price in USD * 10**8.
    uint256 constant aggregatorCoinPriceMult = 10 ** 26;

    // Buffer value - subtract 10**5 from the fee amount in case the price of the native coin updated since the msg.value was calculated in the frontend.
    uint256 constant aggregatorCoinPriceSub = 10 ** 5;

    // Event emitted each time a user pays the fee to use the PreSend service.
    event paymentMade(address indexed user, address currency, uint256 fee, uint256 amountToTransfer, uint256 currencyPrice, address affiliate);

    // Event emitted whenever the PreSendAffiliate contract reference is updated.
    event preSendAffiliateContractUpdated(address indexed newPreSendAffiliateContractAddress);

    // Event emitted whenever the treasury address is updated.
    event treasuryAddressUpdated(address indexed newTreasuryAddress);

    // Event emitted whenever the reference to the aggregator contract is updated.
    event aggregatorReferenceUpdated(address indexed newAggregatorAddress);

    // Event emitted whenever the native coin from fee payments stored in the contract is sent out to the treasury either through the Chainlink keeper or manually.
    event fundsSentToTreasury(address indexed currTreasuryAddress, uint256 amountTransferred);

    // Event emitted whenever the fee divisor is updated.
    event feeDivisorUpdated(uint256 newFeeDivisor);

    // Event emitted whenever the send funds to treasury interval is updated.
    event sendPaymentFeesIntervalUpdated(uint256 indexed newInterval);

    // Event emitted whenever the transfer allowance of a currency is decreased for a user.
    event currencyAllowanceDecreased(address indexed user, address indexed currency, uint256 amount);

    // Event emitted whenever the transfer allowance of a currency is increased for a user.
    event currencyAllowanceIncreased(address indexed user, address indexed currency, uint256 amount);

    // Event emitted whenever the affiliate registration time is updated.
    event affiliateRegistrationTimeUpdated(uint256 newAffiliateRegistrationTime);

    /**
    @dev Initializer function that sets the address of the native dollar token used for fees and the aggregator address. Used in place of constructor since this is an upgradeable contract.
    @param _treasuryAddress the address to send affiliate funds to where they are stored until distributed to the affiliate contract for claiming
    @param _aggregatorAddress the aggregator address for getting native coin prices in USD
    @param _sendPaymentFeesInterval the initial interval for sending payment fees to the treasury address with the Chainlink Keeper
    */
    function initialize(address _treasuryAddress, address _aggregatorAddress, uint256 _sendPaymentFeesInterval) initializer external {
        require(_treasuryAddress != address(0), "Treasury address can't be the 0 address.");
        require(_aggregatorAddress != address(0), "Aggregator address can't be the 0 address.");

        affiliateRegistrationTime = 31536000;
        treasuryAddress = _treasuryAddress;
        aggregator = AggregatorV3Interface(_aggregatorAddress);
        sendPaymentFeesInterval = _sendPaymentFeesInterval;
        lastPaymentFeeSendTimeStamp = block.timestamp;
        feeDivisor = 500;
        netRevenue = 0;
        grossRevenue = 0;

        _setupRole(PAYMENT_ADMIN, msg.sender);
        _setupRole(FEE_ADMIN, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit treasuryAddressUpdated(_treasuryAddress);
        emit aggregatorReferenceUpdated(_aggregatorAddress);
        emit sendPaymentFeesIntervalUpdated(_sendPaymentFeesInterval);
    }

    /**
    @dev Only owner function to set the reference to the PreSend Affiliate smart contract.
    @param _preSendAffiliateAddress the address of the PreSend Affiliate smart contract
    */
    function setPreSendAffiliate(address payable _preSendAffiliateAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_preSendAffiliateAddress != address(0), "PreSend Affiliate address can't be the 0 address.");

        preSendAffiliate = IPreSendAffiliate(_preSendAffiliateAddress);
        emit preSendAffiliateContractUpdated(_preSendAffiliateAddress);
    }

    /**
    @dev Only owner function to set the treasury address.
    @param newTreasuryAddress the address of the treasury
    */
    function setTreasuryAddress(address newTreasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasuryAddress != address(0), "Treasury address can't be the 0 address.");

        treasuryAddress = newTreasuryAddress;
        emit treasuryAddressUpdated(newTreasuryAddress);
    }

    /**
    @dev Only owner function to set the aggregator to determine the native coin price in USD.
    @param newAggregatorAddress the address of the new aggregator
    */
    function setAggregator(address newAggregatorAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAggregatorAddress != address(0), "Aggregator address can't be the 0 address.");

        aggregator = AggregatorV3Interface(newAggregatorAddress);
        emit aggregatorReferenceUpdated(newAggregatorAddress);
    }

    /**
    @dev Private function called by both versions of the payPreSendFee function that handles the logic for charging the PreSend payment fee.
    @param currency The address of the currency the user wants to transfer with PreSend
    @param amount The amount of the currency the user wants to transfer
    @param payment the amount of the native coin the user paid into the smart contract to cover the fee
    @param currencyPrice The price of the currency being transfered with PreSend
    @param affiliate The address of the affiliate wallet that the paying user is tied to
    @param affiliatePercentage the percentage of the fee sent to the affiliate
    */
    function _payPreSendFee(address user, address currency, uint256 amount, uint256 payment, uint256 currencyPrice, address affiliate, uint256 affiliatePercentage) private {
        // Affiliate percentage can be anywhere between 0 and 100 percent, including 0 or 100 percent.
        require(affiliatePercentage <= 100, "Affiliate percentage must be less than or equal to 100.");

        uint256 feeAmount = currencyPrice * amount / 10**18 / feeDivisor;

        // aggregator.latestRoundData returns the coin price in USD * 10**8 hence the 10**26 instead of 10**18
        (, int256 coinPrice, , ,) = aggregator.latestRoundData();

        require(uint256(coinPrice) != 0, "Unable to fetch price of the native coin.");

        // aggregatorCoinPriceMult - Why 10 ** 26? - 10 ** 18 to convert to wei and then multiple by 10**8 since the aggregator returns the coin price in USD * 10**8.
        // aggregatorCoinPriceSub - Subtract 10**5 from the fee amount in case the price of the native coin updated since the msg.value was calculated in the frontend.
        uint256 nativeCoinToDollar = (aggregatorCoinPriceMult / uint256(coinPrice)) - aggregatorCoinPriceSub;

        if (feeAmount < nativeCoinToDollar) {
            feeAmount = nativeCoinToDollar;
        }

        require(payment >= feeAmount, "Payment not enough to cover the fee of the transfer!");

        addressToApprovedAmount[user][currency] += amount;
        grossRevenue += payment;

        if (affiliate != address(0) && preSendAffiliate.affiliateToRegisteredTimestamp(affiliate) > block.timestamp - affiliateRegistrationTime) {
            if (affiliatePercentage > 0) {
                // Step 1 - Update the affiliate balance in the affiliate smart contract to what is was before + the percentage just calculated
                uint256 affiliateAmount = payment * affiliatePercentage / 100;
                affiliateToPreSendRevenue[affiliate] += payment - affiliateAmount;
                netRevenue += payment - affiliateAmount;
                preSendAffiliate.increaseAffiliateAmount(affiliate, affiliateAmount);

                // Step 2 - send the affiliate fee (based on the affiliatePercentage value computed above) to the affiliate in the affiliate contract if they are registered
                // The rest of the native coin just stays in this contract and can be withdrawn by fee admins
                (bool success, ) = address(preSendAffiliate).call{value: affiliateAmount}("");
                require(success, "Failed to send funds to the affiliate.");
            }
            else {
                netRevenue += payment;
            }
        }
        else {
            netRevenue += payment;
        }

        emit paymentMade(user, currency, payment, amount, currencyPrice, affiliate);
    }

    /**
    @dev Payment function without an affiliate address.
    @param currency The address of the currency the user wants to transfer with PreSend
    @param amount The amount of the currency the user wants to transfer
    @param currencyPrice The price of the curreny being transfered with PreSend
    */
    function payPreSendFee(address currency, uint256 amount, uint256 currencyPrice) external payable {
        _payPreSendFee(msg.sender, currency, amount, msg.value, currencyPrice, address(0), 0);
    }

    /**
    @dev Payment function with an affiliate address.
    @param currency The address of the currency the user wants to transfer with PreSend
    @param amount The amount of the currency the user wants to transfer
    @param currencyPrice The price of the curreny being transfered with PreSend
    @param affiliate The address of the affiliate wallet that the paying user is tied to
    @param affiliatePercentage The percentage of the fee that goes to the affiliate
    */
    function payPreSendFee(address currency, uint256 amount, uint256 currencyPrice, address affiliate, uint256 affiliatePercentage) external payable {
        _payPreSendFee(msg.sender, currency, amount, msg.value, currencyPrice, affiliate, affiliatePercentage);
    }

    /**
    @dev Chainlink Keeper function to determine if upkeep needs to be performed (payment fees need to be sent to the treasury address).
    @return upkeepNeeded boolean to determine if upkeep is necessary (i.e. it's time to send the payment fees to the treasury address)
    */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastPaymentFeeSendTimeStamp) > sendPaymentFeesInterval;
    }

    /**
    @dev Chainlink Keeper function to perform upkeep (sending payment fees to the treasury address).
    */
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastPaymentFeeSendTimeStamp) > sendPaymentFeesInterval) {
            lastPaymentFeeSendTimeStamp = block.timestamp;
            uint256 currBalance = address(this).balance;
            (bool success, ) = treasuryAddress.call{value: currBalance}("");
            require(success, "Failed to send native coin to treasury address");
            emit fundsSentToTreasury(treasuryAddress, currBalance);
        }
    }    

    /**
    @dev Payment admin only function to decrease the allowance of a currency a user can transfer.
    @param user the address of the user to decrease the allowance of a currency for
    @param currency the address of the currency to decrease the allowance of
    @param amount the amount to decrease the allowance by
    */
    function decreaseCurrencyAllowance(address user, address currency, uint256 amount) external onlyRole(PAYMENT_ADMIN) {
        require(user != address(0), "User cannot be the zero address.");
        require(addressToApprovedAmount[user][currency] >= amount, "The user doesn't have the allowance for the specified currency to decrease the allowance by the amount given.");
        addressToApprovedAmount[user][currency] -= amount;
        emit currencyAllowanceDecreased(user, currency, amount);
    }

    /**
    @dev Payment admin only function to increase the allowance of a currency a user can transfer.
    @param user the address of the user to increase the allowance of a currency for
    @param currency the address of the currency to increase the allowance of
    @param amount the amount to increase the allowance by
    */
    function increaseCurrencyAllowance(address user, address currency, uint256 amount) external onlyRole(PAYMENT_ADMIN) {
        require(user != address(0), "User cannot be the zero address.");
        addressToApprovedAmount[user][currency] += amount;
        emit currencyAllowanceIncreased(user, currency, amount);
    }

    /**
    @dev Payment admin only function to update the amount of seconds an affiliate is registered for.
    @param newAffiliateRegistrationTime the new registration time in seconds for affiliates before they need to reregister
    */
    function setAffiliateRegistrationTime(uint256 newAffiliateRegistrationTime) external onlyRole(PAYMENT_ADMIN) {
        require(newAffiliateRegistrationTime > 0, "Affiliate registration time must be greater than zero seconds.");
        affiliateRegistrationTime = newAffiliateRegistrationTime;
        emit affiliateRegistrationTimeUpdated(newAffiliateRegistrationTime);
    }

    /**
    @dev Fee admin only function to manually send PreSend transaction fees from the contract to the treasury address (usually the Chainlink Keeper will take care of this).
    */
    function extractFees() external onlyRole(FEE_ADMIN) {
        uint256 currBalance = address(this).balance;
        (bool success, ) = treasuryAddress.call{value: currBalance}("");
        require(success, "Failed to send native coin to the treasury address");
        emit fundsSentToTreasury(treasuryAddress, currBalance);
    }

    /**
    @dev Only owner function to change the payment admin.
    @param newAdmin address of the user to make a payment admin so they can update the addressToApprovedAmount mapping
    @param oldAdmin address of the user to remove from the payment admin role
    */
    function changePaymentAdmin(address newAdmin, address oldAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "New admin address cannot be the zero address.");
        require(oldAdmin != address(0), "Old admin address cannot be the zero address.");
        _grantRole(PAYMENT_ADMIN, newAdmin);
        _revokeRole(PAYMENT_ADMIN, oldAdmin);
    }

    /**
    @dev Only owner function to change the fee admin.
    @param newAdmin address of the user to make a fee admin so they can take fees from the contract
    @param oldAdmin address of the user to remove from the fee admin role
    */
    function changeFeeAdmin(address newAdmin, address oldAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "New admin address cannot be the zero address.");
        require(oldAdmin != address(0), "Old admin address cannot be the zero address.");
        _grantRole(FEE_ADMIN, newAdmin);
        _revokeRole(FEE_ADMIN, oldAdmin);
    }

    /**
    @dev Only owner function to set the divisor for the token percentage part of the PreSend transfer fee.
    @param newFeeDivisor the new divisor for the token percentage part of the fee
    */
    function setFeeDivisor(uint256 newFeeDivisor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeDivisor = newFeeDivisor;
        emit feeDivisorUpdated(newFeeDivisor);
    }

    /**
    @dev Only owner function to set the interval that determines how often the native coin stored in the contract from fee payments is sent to the treasury.
    @param newInternval the interval to determine how often funds are sent to the treasury from this contract
    */
    function setSendPaymentFeesInternval(uint256 newInternval) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sendPaymentFeesInterval = newInternval;
        emit sendPaymentFeesIntervalUpdated(newInternval);
    }

    uint256[49] private __gap;
}