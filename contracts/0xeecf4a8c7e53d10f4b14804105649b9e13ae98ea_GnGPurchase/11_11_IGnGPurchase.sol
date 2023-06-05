// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGnGPurchase {
    /**
     * @dev Supported payment types that can be used to purchase Goblins.
     */
    enum PaymentType {
        ETH,
        USDC,
        ASTO,
        SYLO
    }

    /**
     * @dev Error with `errMsg` message for input validation.
     */
    error InvalidInput(string errMsg);

    /**
     * @dev Error with `errMsg` message for withdrawn.
     */
    error WithdrawError(string errMsg);

    /**
     * @dev Emitted when supported payments received from `sender`.
     */
    event PaymentReceived(
        address indexed sender,
        bytes32 indexed orderId,
        uint256 goblinAmount,
        PaymentType _type,
        uint256 paidTokenAmount
    );

    /**
     * @dev Emitted when Goblin price in USDC updated to `priceInUSDC`.
     */
    event PriceUpdated(address indexed operator, uint256 priceInUSDC);

    /**
     * @dev Emitted when maximum amount per tx updated to `router
     */
    event MaxAmountUpdated(address indexed operator, uint256 amount);

    /**
     * @dev Emitted when all ETH withdrawn to `recipient`
     */
    event ETHWithdrawn(address indexed operator, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when all `contractAddress` token withdrawn to `recipient`
     */
    event ERC20Withdrawn(address indexed operator, address indexed recipient, address contractAddress, uint256 amount);

    /**
     * @dev Buy `goblinAmount` Goblins with ETH
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithETH(bytes32 orderId, uint256 goblinAmount) external payable;

    /**
     * @dev Buy `goblinAmount` Goblins with USDC token
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithUSDC(bytes32 orderId, uint256 goblinAmount) external;

    /**
     * @dev Buy `goblinAmount` Goblins with ASTO token
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithASTO(bytes32 orderId, uint256 goblinAmount) external;

    /**
     * @dev Buy `goblinAmount` Goblins with SYLO token
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithSYLO(bytes32 orderId, uint256 goblinAmount) external;

    /**
     * @dev Convert to WETH value equivalent to `usdcValue` USDC
     * @param usdcValue The value in USDC to convert
     */
    function usdcToWETH(uint256 usdcValue) external view returns (uint256);

    /**
     * @dev Convert to ASTO value equivalent to `usdcValue` USDC
     * @param usdcValue The value in USDC to convert
     */
    function usdcToASTO(uint256 usdcValue) external view returns (uint256);

    /**
     * @dev Convert to SYLO value equivalent to `usdcValue` USDC
     * @param usdcValue The value in USDC to convert
     */
    function usdcToSYLO(uint256 usdcValue) external view returns (uint256);

    /**
     * @dev Update maximum goblin amount that can be purchased in 1 tx
     * @dev This function can only be called from contract owner
     * @param amount The new amount to be updated
     */
    function updateMaxAmount(uint256 amount) external;

    /**
     * @dev Update Goblin price in USDC
     * @dev This function can only be called from contract owner
     * @param priceInUSDC The new Goblin price in USDC to be updated
     */
    function updatePrice(uint256 priceInUSDC) external;

    /**
     * @dev Withdraw all ETH from this contract to the recipient `recipient`
     * @dev This function can only be called from contract owner
     * @param recipient Wallet address of the recipient
     */
    function withdrawETH(address recipient) external;

    /**
     * @dev Withdraw all ERC20 token balance to the recipient `recipient`
     * @param recipient  Wallet address of the recipient
     */
    function withdrawERC20(address contractAddress, address recipient) external;

    /**
     * @dev Pause the contract
     * @dev This function can only be called from contract owner
     */
    function pause() external;

    /**
     * @dev Unpause the contract
     * @dev This function can only be called from contract owner
     */
    function unpause() external;
}