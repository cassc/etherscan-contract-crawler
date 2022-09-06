pragma solidity 0.8.14;

interface ISaleListener {
    /**
     * Callback for a listener contract (Vesting) to listen in to new sales
     *
     * @param _beneficiary The beneficiary of the new sale
     * @param _amount The amount of asset purchased
     */
    function onSale(address _beneficiary, uint256 _amount)
        external
        returns (bytes4 selector);

    /**
     * Retrieves the total amount of $UCO allocated to a given holder via the public sale
     *
     * @param _holder The account to check
     * @return amount The amount of $UCO allocated via public sale
     */
    function getSaleAllocation(address _holder)
        external
        view
        returns (uint256 amount);

    /**
     * @return total Total amount of $UCO available for sale
     * @return remaining Remaining amount of $UCO still available for sale
     */
    function getSaleAmounts()
        external
        view
        returns (uint256 total, uint256 remaining);
}