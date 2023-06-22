// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

/**
* @dev Interface of Digital Reserve contract.
*/
interface IDigitalReserve {
    /**
     * @dev Returns length of the portfolio asset tokens. 
     * Can be used to get token addresses and percentage allocations.
     */
    function strategyTokenCount() external view returns (uint256);

    /**
     * @dev Returns a strategy token address. 
     * @param index The index of a strategy token
     */
    function strategyTokens(uint8 index) external view returns (address, uint8);

    /**
     * @dev Returns withdrawal withdrawal fee.
     * @return The first value is fraction, the second one is fraction base
     */
    function withdrawalFee() external view returns (uint8, uint8);

    /**
     * @dev Returns Proof of Deposit price decimal.
     * Price should be displayed as `price / (10 ** priceDecimals)`.
     */
    function priceDecimals() external view returns (uint8);

    /**
     * @dev Returns total strategy tokens stored in an array.
     * The output amount sequence is the strategyTokens() array sequence.
     */
    function totalTokenStored() external view returns (uint256[] memory);

    /**
     * @dev Returns how much user's vault share in DRC amount.
     * @param user Address of a DR user
     * @param percentage Percentage of user holding
     * @return The first output is total worth in DRC, 
     * second one is total DRC could withdraw (exclude fees), 
     * and last output is fees in wei.
     */
    function getUserVaultInDrc(address user, uint8 percentage) external view returns (uint256, uint256, uint256);

    /**
     * @dev Get deposit price impact
     * @param drcAmount DRC amount user want to deposit.
     * @return The price impact on the base of 10000, 
     */
    function depositPriceImpact(uint256 drcAmount) external view returns (uint256);

    /**
     * @dev Proof of Deposit net unit worth.
     */
    function getProofOfDepositPrice() external view returns (uint256);

    /**
     * @dev Deposit DRC to DR.
     * @param drcAmount DRC amount user want to deposit.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function depositDrc(uint256 drcAmount, uint32 deadline) external;

    /**
     * @dev Withdraw DRC from DR.
     * @param drcAmount DRC amount user want to withdraw.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function withdrawDrc(uint256 drcAmount, uint32 deadline) external;

    /**
     * @dev Withdraw a percentage of holding from DR.
     * @param percentage Percentage of holding user want to withdraw.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function withdrawPercentage(uint8 percentage, uint32 deadline) external;

    /**
     * @dev Emit when strategy set or change function is called by owner.
     * @param oldTokens Pervious strategy's token addresses.
     * @param oldPercentage Pervious strategy's token allocation percentages.
     * @param newTokens New strategy's token addresses.
     * @param newPercentage New strategy's token allocation percentages.
     * @param tokensStored How much each token is stored.
     */
    event StrategyChange(
        address[] oldTokens, 
        uint8[] oldPercentage, 
        address[] newTokens, 
        uint8[] newPercentage, 
        uint256[] tokensStored
    );
    
    /**
     * @dev Emit each time a rebalance function is called by owner.
     * @param strategyTokens Strategy token addresses.
     * @param tokenPercentage Strategy token allocation percentages.
     * @param tokensStored How much each token is stored.
     */
    event Rebalance(
        address[] strategyTokens, 
        uint8[] tokenPercentage, 
        uint256[] tokensStored
    );
    
    /**
     * @dev Emit each time a deposit action happened.
     * @param user Address made the deposit.
     * @param amount DRC amount deposited.
     * @param podMinted New DR-POD minted.
     * @param podTotalSupply New DR-POD total supply.
     * @param tokensStored How much each token is stored.
     */
    event Deposit(
        address indexed user, 
        uint256 amount, 
        uint256 podMinted, 
        uint256 podTotalSupply, 
        uint256[] tokensStored
    );
    
    /**
     * @dev Emit each time a withdraw action happened.
     * @param user Address made the withdrawal.
     * @param amount DRC amount withdrawn.
     * @param fees Withdrawal fees charged in wei.
     * @param podBurned DR-POD burned.
     * @param podTotalSupply New DR-POD total supply.
     * @param tokensStored How much each token is stored.
     */
    event Withdraw(
        address indexed user, 
        uint256 amount, 
        uint256 fees, 
        uint256 podBurned, 
        uint256 podTotalSupply, 
        uint256[] tokensStored
    );
}