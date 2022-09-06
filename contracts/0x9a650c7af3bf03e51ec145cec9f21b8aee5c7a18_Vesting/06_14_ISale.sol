pragma solidity 0.8.14;

interface ISale {
    //
    // Events
    //

    /// Emitted when a purchase is made
    event Purchase(
        address indexed buyer,
        uint256 paymentAmount,
        uint256 assetAmount
    );

    //
    // Functions
    //
    /** Allows accounts to buy into the public token sale
     *
     * @notice Should only allow whitelisted (KYC'd) addresses @notice Should
     * only work within the timesframes of the public sale
     *
     * @param _amountDesired Desired amount of $UCO @return amountOut Final
     * amount of $UCO allocated (may be lower than _amountDesired if supply is
     * insufficient)
     */
    function buy(uint256 _amountDesired) external returns (uint256 amountOut);

    /// The timestamp at which the sale starts
    function start() external view returns (uint256 startTimestamp);

    /// The timestamp for the first price increase
    function checkpoint1() external view returns (uint256 startTimestamp);

    /// The timestamp for the second price increase
    function checkpoint2() external view returns (uint256 startTimestamp);

    /// The timestamp at which the sale ends
    function end() external view returns (uint256 endTimestamp);

    /// Treasury address who serves as beneficiary of all payment currency;
    function treasury() external view returns (address);

    /// The total supply of the public sale
    function totalSupply() external view returns (uint256 supply);

    /// The remaining supply of the public sale
    function remainingSupply() external view returns (uint256 supply);

    /// Address of the payment currency used
    function paymentToken() external view returns (address);

    /// How much was raised so far
    function raised() external view returns (uint256);

    /// How much was sold
    function sold() external view returns (uint256);

    /// How much was contributed by a given account
    function contributions(address) external view returns (uint256);

    /// How much was purchased by a given account
    function purchased(address) external view returns (uint256);

    /// Converts {paymentToken} -> $UCO
    function paymentAmountToAssetAmount(uint256 _paymentAmount)
        external
        view
        returns (uint256 assetAmount);

    /// Converts $UCO -> {paymentToken}
    function assetAmountToPaymentAmount(uint256 _assetAmount)
        external
        view
        returns (uint256 paymentAmount);
}