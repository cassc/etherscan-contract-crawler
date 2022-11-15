// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDolzToken.sol";

struct SaleSettings {
    address token;
    address wallet;
    uint256 saleStart;
    uint256 saleEnd;
    uint256 withdrawalStart;
    uint256 withdrawPeriodDuration;
    uint256 withdrawPeriodNumber;
    uint256 minBuyValue;
    uint256 maxTokenAmountPerAddress;
    uint256 exchangeRate;
    uint256 referralRewardPercentage;
    uint256 amountToSell;
}

/**
 * @notice ICO smart contract with start and end, vesting and referral reward.
 * Payments are meant to be made in ERC20 stable coins.
 * @dev Only the address of the token to be sold has to be set at deployment.
 * The rest is accessible via setters until the start of the sale.
 */
contract DolzCrowdsale2 is Ownable {
    using SafeERC20 for IERC20;

    // Token to be sold
    address private immutable token;
    // Wallet that receives the payment tokens
    address private wallet;
    // Timestamp in seconds of the start of the ICO
    uint256 internal saleStart;
    // Timestamp in seconds of the end of the ICO
    uint256 internal saleEnd;
    // Timestamp in seconds when users can start to withdraw
    uint256 internal withdrawalStart;
    // Duration in seconds of each vesting period
    uint256 private withdrawPeriodDuration;
    // Number of vesting period
    uint256 private withdrawPeriodNumber;
    // Minimum value to buy in dollars
    uint256 private minBuyValue;
    // Maximum token amount to be bought per address
    uint256 private maxTokenAmountPerAddress;
    // Exchange rate between stable coins and token
    // E.g. 125 would mean you get 83,3333 tokens for 1 dollar, so the price would be
    // 1,2cts per token (1 dollar / 83,333333 = 0.012)
    uint256 private exchangeRate;
    // Percentage of the tokens bought that referrals get
    // E.g. for a 30 value, if a buyer buys 100 tokens the referral will get 30
    uint256 private referralRewardPercentage;
    // Total number of tokens sold (exculdes referral rewards)
    uint256 internal soldAmount;
    // Total number of tokens given to referral rewards
    uint256 internal rewardsAmount;
    // Amount of tokens available to buyers
    uint256 private amountToSell;
    // Burn remaining tokens already called
    bool private burnCalled;

    // Set the address of token authorized for payments to true
    mapping(address => bool) private authorizedPaymentCurrencies;
    // Map buyers and referrals addresses to the amount they can claim
    mapping(address => uint256) private userToClaimableAmount;
    // Map buyers and referrals addresses to the amount they already claimed
    mapping(address => uint256) private userToWithdrewAmount;
    // Track referral amounts
    mapping(address => uint256) private userToReferralRewardAmount;

    event WalletUpdated(address newWallet, address indexed updater);
    event SaleStartUpdated(uint256 newSaleStart, address indexed updater);
    event SaleEndUpdated(uint256 newSaleEnd, address indexed updater);
    event WithdrawalStartUpdated(
        uint256 newWithdrawalStart,
        address indexed updater
    );
    event WithdrawPeriodDurationUpdated(
        uint256 newWithdrawPeriodDuration,
        address indexed updater
    );
    event WithdrawPeriodNumberUpdated(
        uint256 newWithdrawPeriodNumber,
        address indexed updater
    );
    event MinBuyValueUpdated(uint256 newMinBuyValue, address indexed updater);
    event MaxTokenAmountPerAddressUpdated(
        uint256 newMaxTokenAmountPerAddress,
        address indexed updater
    );
    event ExchangeRateUpdated(uint256 newExchangeRate, address indexed updater);
    event ReferralRewardPercentageUpdated(
        uint256 newReferralRewardPercentage,
        address indexed updater
    );
    event AmountToSellUpdated(uint256 newAmountToSell, address indexed updater);

    event PaymentCurrenciesAuthorized(
        address[] tokens,
        address indexed updater
    );
    event PaymentCurrenciesRevoked(
        address[] tokens,
        address indexed updater
    );

    event ReferralRegistered(address newReferral);
    event TokenBought(
        address indexed account,
        address indexed stableCoin,
        uint256 value,
        address indexed referral
    );

    event TokenWithdrew(address indexed account, uint256 amount);
    event RemainingTokensBurnt(uint256 remainingBalance);

    /**
     * @dev Check if the sale has already started.
     */
    modifier onlyBeforeSaleStart() {
        if (saleStart > 0) {
            require(
                block.timestamp < saleStart,
                "DolzCrowdsale: sale already started"
            );
        }
        _;
    }

    /// @dev Check if the withdrawal period has start
    modifier withdrawalStarted(){
        require(block.timestamp >= withdrawalStart);
        _;
    }
    
    constructor(
        address _token,
        address _wallet,
        uint256 _saleStart,
        uint256 _saleEnd,
        uint256 _withdrawalStart,
        uint256 _withdrawPeriodDuration,
        uint256 _withdrawPeriodNumber,
        uint256 _minBuyValue,
        uint256 _maxTokenAmountPerAddress,
        uint256 _exchangeRate,
        uint256 _referralRewardPercentage,
        uint256 _amountToSell
    ) {
        token = _token;
        wallet = _wallet;
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        withdrawalStart = _withdrawalStart;
        withdrawPeriodDuration = _withdrawPeriodDuration;
        withdrawPeriodNumber = _withdrawPeriodNumber;
        minBuyValue = _minBuyValue;
        maxTokenAmountPerAddress = _maxTokenAmountPerAddress;
        exchangeRate = _exchangeRate;
        referralRewardPercentage = _referralRewardPercentage;
        amountToSell = _amountToSell;
        burnCalled = false;
    }

    /**
     * @notice Enable to get all the infos about the sale.
     * @return See state variables comments.
     */
    function getSaleSettings() external view returns (SaleSettings memory) {
        return
            SaleSettings(
                token,
                wallet,
                saleStart,
                saleEnd,
                withdrawalStart,
                withdrawPeriodDuration,
                withdrawPeriodNumber,
                minBuyValue,
                maxTokenAmountPerAddress,
                exchangeRate,
                referralRewardPercentage,
                amountToSell
            );
    }

    function getSoldAmount() external view returns (uint256) {
        return soldAmount;
    }

    /**
     * @notice Returns the amount of token a user will be able to withdraw after withdrawal start,
     * depending on vesting periods.
     * @param account Address to get claimable amount of.
     * @return Number of claimable tokens.
     */
    function getClaimableAmount(address account)
        external
        view
        returns (uint256)
    {
        return userToClaimableAmount[account];
    }

    /**
     * @notice Returns the amount earned as a referral,
     *
     * @param account Address to get referral amount.
     * @return Number of rewards.
     */
    function getReferralRewardsAmount(address account)
        external
        view
        returns (uint256)
    {
        return userToReferralRewardAmount[account];
    }

    /**
     * @notice Returns the amount of token a user has already withdrew.
     * @param account Address to get withdrew amount of.
     * @return Number of withdrew tokens.
     */
    function getWithdrewAmount(address account)
        external
        view
        returns (uint256)
    {
        return userToWithdrewAmount[account];
    }

    /**
     * @notice Enable to know if a token is authorized to buy the ICO token.
     * @param paymentCurrency Address of the token to check.
     * @return True if the token is authorized, false if not.
     */
    function isAuthorizedPaymentCurrency(address paymentCurrency)
        external
        view
        returns (bool)
    {
        return authorizedPaymentCurrencies[paymentCurrency];
    }

    /**
     * @notice Enable to update the address that will receive the payments for token sales.
     * @dev The wallet address can be updated at any time, even after the start of the sale.
     * Only executable by the owner of the contract.
     * @param newWallet Address of the account that will receive the payments.
     */
    function setWallet(address newWallet) external onlyOwner {
        wallet = newWallet;
        emit WalletUpdated(newWallet, msg.sender);
    }

    /**
     * @notice Enable to update the start date of the sale.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newSaleStart Timestamp in seconds from when the users will be able to buy the tokens.
     */
    function setSaleStart(uint256 newSaleStart)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        saleStart = newSaleStart;
        emit SaleStartUpdated(newSaleStart, msg.sender);
    }

    /**
     * @notice Enable to update the end date of the sale.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newSaleEnd Timestamp in seconds from when the users will not be able to buy the tokens anymore.
     */
    function setSaleEnd(uint256 newSaleEnd)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        saleEnd = newSaleEnd;
        emit SaleEndUpdated(newSaleEnd, msg.sender);
    }

    /**
     * @notice Enable to update the start date of the withdrawal period.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newWithdrawalStart Timestamp in seconds from when the users will be able to withdraw their
     * claimable amount, according to the vesting configuration.
     */
    function setWithdrawalStart(uint256 newWithdrawalStart)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        withdrawalStart = newWithdrawalStart;
        emit WithdrawalStartUpdated(newWithdrawalStart, msg.sender);
    }

    /**
     * @notice Enable to update the duration of each withdrawal period.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newWithdrawPeriodDuration Duration in seconds of 1 withdrawal period.
     */
    function setWithdrawPeriodDuration(uint256 newWithdrawPeriodDuration)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        withdrawPeriodDuration = newWithdrawPeriodDuration;
        emit WithdrawPeriodDurationUpdated(
            newWithdrawPeriodDuration,
            msg.sender
        );
    }

    /**
     * @notice Enable to update the number of withdrawal periods.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newWithdrawPeriodNumber Integer representing the number of withdrawal period. Also defines
     * how much of the claimable amount will be withdrawal at each period.
     * E.g. with 10 withdrawal periods, the claimable amount will be split into 10 parts, resulting in
     * a 10% withdrawal for each period.
     */
    function setWithdrawPeriodNumber(uint256 newWithdrawPeriodNumber)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        withdrawPeriodNumber = newWithdrawPeriodNumber;
        emit WithdrawPeriodNumberUpdated(newWithdrawPeriodNumber, msg.sender);
    }

    /**
     * @notice Enable to update the minimum value in dollars to buy per sale.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newMinBuyValue Integer representing the minimum amount of stable coins to receive at
     * each sale.
     */
    function setMinBuyValue(uint256 newMinBuyValue)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        minBuyValue = newMinBuyValue;
        emit MinBuyValueUpdated(newMinBuyValue, msg.sender);
    }

    /**
     * @notice Enable to update the maximum amount of tokens an address can buy.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newMaxTokenAmountPerAddress Integer representing the maximum amount of tokens buyable
     * per address.
     */
    function setMaxTokenAmountPerAddress(uint256 newMaxTokenAmountPerAddress)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        maxTokenAmountPerAddress = newMaxTokenAmountPerAddress;
        emit MaxTokenAmountPerAddressUpdated(
            newMaxTokenAmountPerAddress,
            msg.sender
        );
    }

    /**
     * @notice Enable to update the exchange rate per token (tokens/USD).
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newExchangeRate Integer representing the exchange rate.
     */
    function setExchangeRate(uint256 newExchangeRate)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        exchangeRate = newExchangeRate;
        emit ExchangeRateUpdated(newExchangeRate, msg.sender);
    }

    /**
     * @notice Enable to update the referral reward percentage.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newReferralRewardPercentage Integer representing the reward percentage.
     * E.g. 30 means the referral reward will be 30% of the amount of token bought by the sponsored user.
     */
    function setReferralRewardPercentage(uint256 newReferralRewardPercentage)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        referralRewardPercentage = newReferralRewardPercentage;
        emit ReferralRewardPercentageUpdated(
            newReferralRewardPercentage,
            msg.sender
        );
    }

    /**
     * @notice Enable to update the amount of token available to sell.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param newAmountToSell Integer representing the amount of token to sell.
     */
    function setAmountToSell(uint256 newAmountToSell)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        amountToSell = newAmountToSell;
        emit AmountToSellUpdated(newAmountToSell, msg.sender);
    }

    /**
     * @notice Enable to authorize tokens to be used as payment during sales.
     * @dev Only executable before the start of the sale.
     * Only executable by the owner of the contract.
     * @param tokens Array of addresses of the tokens to authorize. Meant to be stable coins.
     */
    function authorizePaymentCurrencies(address[] memory tokens)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i += 1) {
            authorizedPaymentCurrencies[tokens[i]] = true;
        }
        emit PaymentCurrenciesAuthorized(tokens, msg.sender);
    }

    /// @notice Allow owner to revoke token's authorization to be used as payment during sales.
    /// @dev Only executable before the start of the sale & by the contract owner.
    /// @param tokens Array of addresses of the tokens to revoke authorization.
    function revokeAuthorizationPaymentCurrencies(address[] memory tokens)
        external
        onlyBeforeSaleStart
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i += 1) {
            authorizedPaymentCurrencies[tokens[i]] = false;
        }
        emit PaymentCurrenciesRevoked(tokens, msg.sender);
    }

    /**
     * @notice Enable users to buy tokens.
     * @dev User needs to approve this contract to spend the `value` parameter on the `stableCoin`
     * parameter.
     * @param stableCoin Address of the token to be used as payment for the sale.
     * @param value Amount of payment tokens to be spent.
     * @param referral Address of the referral of the user. Use zero address if no referral.
     */
    function buyToken(
        address stableCoin,
        uint256 value,
        address referral
    ) external {
        // Checks if the `stableCoin` address is authorized
        require(
            authorizedPaymentCurrencies[stableCoin],
            "DolzCrowdsale: unauthorized token"
        );
        // Checks if the sale has started
        require(
            block.timestamp >= saleStart,
            "DolzCrowdsale: sale not started yet"
        );
        // Checks if the sale has not ended
        require(block.timestamp <= saleEnd, "DolzCrowdsale: sale ended");
        // Checks if the minimum buy value is provided
        require(value >= minBuyValue, "DolzCrowdsale: under minimum buy value");

        // Computes the number of tokens the user will receive
        uint256 claimableAmount = (value * exchangeRate) / 1e6;

        // Checks if this sale will exceed the maximum token amount per address allowed
        require(
            userToClaimableAmount[msg.sender] + claimableAmount <=
                maxTokenAmountPerAddress,
            "DolzCrowdsale: above maximum token amount per address"
        );
        // Checks if this sale will exceed the number of tokens avaible to sell
        require(
            soldAmount + claimableAmount <= amountToSell,
            "DolzCrowdsale: not enough tokens available"
        );
        userToClaimableAmount[msg.sender] += claimableAmount;
        soldAmount += claimableAmount;

        // If a referral is mentioned, adds the reward to its claimable balance
        // Checks if the referral is not the buyer
        if (referral != address(0) && referral != msg.sender) {
            uint256 referralReward = (claimableAmount *
                referralRewardPercentage) / 100;

            userToClaimableAmount[referral] += referralReward;

            //track referral amount
            userToReferralRewardAmount[referral] += referralReward;

            //total referral amount
            rewardsAmount += referralReward;
        }

        emit TokenBought(msg.sender, stableCoin, value, referral);

        IERC20(stableCoin).safeTransferFrom(msg.sender, wallet, value);
    }

    /**
     * @notice Enable users to withdraw their tokens, depending on withdrawal start and vesting configuration.
     */
    function withdrawToken() external withdrawalStarted{
        // Computes the number of withdrawal periods that have passed
        // Reverts if before withdrawalStart, so there is no need to check for that
        uint256 periodsElapsed = (block.timestamp - withdrawalStart) /
            withdrawPeriodDuration +
            1;

        uint256 amountToSend;
        // Checks if all the withdrawal periods have passed, to be able to delete claimable and withdrew
        // balances if so and make substantial gas savings
        if (periodsElapsed >= withdrawPeriodNumber) {
            // All the withdrawal periods have passed, so we send all the remaining claimable balance
            amountToSend =
                userToClaimableAmount[msg.sender] -
                userToWithdrewAmount[msg.sender];
            delete userToClaimableAmount[msg.sender];
            delete userToWithdrewAmount[msg.sender];
        } else {
            // Computes how many tokens the user can withdraw per period
            uint256 withdrawableAmountPerPeriod = userToClaimableAmount[
                msg.sender
            ] / withdrawPeriodNumber;
            // Computes how much the user can withdraw since the begining, minest the amount it already withdrew
            amountToSend =
                withdrawableAmountPerPeriod *
                periodsElapsed -
                userToWithdrewAmount[msg.sender];
            userToWithdrewAmount[msg.sender] += amountToSend;
        }

        emit TokenWithdrew(msg.sender, amountToSend);

        // We know our implementation returns true if success, so no need to use safeTransfer
        require(
            IERC20(token).transfer(msg.sender, amountToSend),
            "DolzCrowdsale: transfer failed"
        );
    }

    /**
     * @notice Enable to burn all the unsold tokens after the end of the sale.
     * @dev Anyone can call this function.
     */
    function burnRemainingTokens() external onlyOwner {
        // Checks if the sale has ended
        require(block.timestamp > saleEnd, "DolzCrowdsale: sale not ended yet");
        // must be called before the withdrawal start
        require(
            block.timestamp < withdrawalStart,
            "Too late to burn, withdrawal already started"
        );
        // avoid to be called several times
        require(burnCalled == false, "Burn already called!");

        uint256 balance = IERC20(token).balanceOf(address(this));

        //sold out ?
        require(balance - soldAmount - rewardsAmount > 0, "Nothing to burn");

        emit RemainingTokensBurnt(balance - soldAmount - rewardsAmount);
        IDolzToken(token).burn(balance - soldAmount - rewardsAmount);

        burnCalled = true;
    }
}