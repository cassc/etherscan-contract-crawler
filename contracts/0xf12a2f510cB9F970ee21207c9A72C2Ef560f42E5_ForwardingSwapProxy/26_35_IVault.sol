interface IVault {
    /// @dev Event used when the contract receives ETH
    event Received(address indexed from, uint256 value);
    /// @dev Event used when the contract is paid ETH, this will occur when fees have been deducted and transferred to the Vault contract for holding
    event PaidFees(address indexed from, uint256 value);
    /// @dev Event used whenever an admin claims fees from the contract
    event FeesClaimed(address indexed from, uint256 value);

    /// @dev To allow the contract to receive ETH
    receive() external payable;

    /// @notice Allows an admin to claim the ETH balance of the contract
    function claimFees() external;

    /// @notice This function is called whenever fees have been deducted from a user and transffered into the Vault for holding
    /// @param _sender The user who has been deducted a fee
    /// @param _amount The fee amount
    function paidFees(address _sender, uint256 _amount) external payable;

    /// @notice Allows an admin to set the balance limit for wallets that have the HOT_WALLET role
    /// @param _walletBalanceLimit The updated balance limit
    function setWalletBalanceLimit(uint256 _walletBalanceLimit) external;

    /// @notice Allows an admin to top up registered HOT_WALLETS, these wallets will be used for sponosoring transactions and this method allows updating all of them with a single contract call
    function topUpHotWallets() external payable;

    /// @notice This allows us to easily see the total amount of ETH required to top-up all hot wallets. Used before calling the topUpHotWallets function
    /// @return totalETH The total amount of ETH required
    function ethRequiredForHotWalletTopup()
        external
        view
        returns (uint256 totalETH);
}