// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "../libraries/utils/DataTypes.sol";

interface IKyokoPool {
    /**
     * @dev Emitted on deposit()
     * @param reserveId The id of the reserve
     * @param user The beneficiary of the deposit, receiving the kTokens
     * @param onBehalfOf The beneficiary of the deposit, receiving the kTokens
     * @param amount The amount deposited
     **/
    event Deposit(
        uint256 indexed reserveId,
        address indexed user,
        address indexed onBehalfOf,
        uint256 amount
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserveId The id of the reserve
     * @param user The address initiating the withdrawal, owner of kTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        uint256 indexed reserveId,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserveId The id of the reserve
     * @param borrowId The id of the borrow info
     * @param asset The address of the borrowed nft
     * @param nftId The tokenId of the borrowed nft
     * @param borrowMode The rate mode: 1 for Stable, 2 for Variable
     * @param amount The amount of the borrow
     * @param borrowRate The numeric rate at which the user has borrowed
     **/
    event Borrow(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed asset,
        uint256 nftId,
        uint256 borrowMode,
        uint256 amount,
        uint256 borrowRate
    );

    /**
     * @dev Emitted on repay()
     * @param reserveId The id of the reserve
     * @param borrowId The id of the borrow info
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param nft The nft corresponding to repayment
     * @param nftId The tokenId of the borrowed nft
     * @param amount The amount repaid
     **/
    event Repay(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address user,
        address indexed nft,
        uint256 nftId,
        uint256 amount
    );

    event LiquidationCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user,
        address nft,
        uint256 id,
        uint256 amount,
        uint256 time
    );

    event BidCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user,
        uint256 amount,
        uint256 time
    );

    event ClaimCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user,
        uint256 time
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserveId The id of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        uint256 indexed reserveId,
        address indexed user
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when new stable debt is increased
     * @param reserveId The id of the reserve
     * @param asset The address of nft
     * @param user The address of the user who triggered the minting
     * @param amount The amount minted
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param newRate The rate of the debt after the minting
     * @param newTotalSupply The new total supply of the stable debt token after the action
     **/
    event StableDebtIncrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 newRate,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new stable debt is decreased
     * @param reserveId The id of the reserve
     * @param user The address of the user
     * @param amount The amount being burned
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The the increase in balance since the last action of the user
     * @param avgStableRate The new average stable rate after the burning
     * @param newTotalSupply The new total supply of the stable debt token after the action
     **/
    event StableDebtDecrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new varibale debt is increased
     * @param reserveId The id of the reserve
     * @param asset The address performing the nft
     * @param user The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event VariableDebtIncrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Emitted when variable debt is decreased
     * @param reserveId The id of the reserve
     * @param asset The address of the nft
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event VariableDebtDecrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 index
    );

    event SetMinBorrowTime(uint40 time);

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying kTokens.
     * @param reserveId The id of the reserve
     * @param onBehalfOf The beneficiary of the deposit, receiving the kTokens
     **/
    function deposit(uint256 reserveId, address onBehalfOf) external payable;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent kTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param reserveId The id of the reserve
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole kToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        uint256 reserveId,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow an estimate `amount` of the reserve underlying asset according to the value of the nft
     * @param reserveId The id of the reserve
     * @param asset The address of the nft to be borrowed
     * @param nftId The tokenId of the nft to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address that will recieve the borrow asset and debt token (must be msg.sender or the msg.sender must be punkGateway)
     **/
    function borrow(
        uint256 reserveId,
        address asset,
        uint256 nftId,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve
     * @param borrowId The id of the borrow to repay
     * @param onBehalfOf The address that will burn the debt token (must be msg.sender or the msg.sender must be punkGateway)
     * @return The final amount repaid
     **/
    function repay(
        uint256 borrowId,
        address onBehalfOf
    ) external payable returns (uint256);

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param reserveId The id of the reserve
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(
        uint256 reserveId,
        address user
    ) external;

    /**
     * @dev Function to liquidate an expired borrow info.
     * @param borrowId The id of liquidate borrow target
     **/
    function liquidationCall(
        uint256 borrowId
    ) external payable;

    /**
     * @dev Function to bid for the liquidate auction.
     * @param borrowId The id of liquidate borrow target
     **/
    function bidCall(uint256 borrowId) external payable;

    /**
     * @dev Function to claim the liquidate NFT.
     * @param borrowId The id of liquidate borrow target
     **/
    function claimCall(uint256 borrowId) external;

    function claimCall(
        uint256 borrowId,
        address onBehalfOf
    ) external;

    /**
     * @dev Returns the list of user's borrowId
     * @param user The address of the user
     **/
    function getUserBorrowList(
        address user
    ) external view returns (uint256[] memory borrowIds);

    /**
     * @dev Returns the list of borrowId in auction
     **/
    function getAuctions() external view returns (uint256[] memory);

    /**
     * @dev Returns the list of user's borrowId
     * @param borrowId The id of the borrow info
     **/
    function getDebt(uint256 borrowId) external view returns (uint256 debt);

    function getInitialLockTime(
        uint256 reserveId
    ) external view returns (uint256);

    function enabledLiquidation(uint256 borrowId) external view returns (bool);

    function initReserve(
        address asset,
        address kTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function updateReserveNFT(
        uint256 reserveId,
        address asset,
        bool flag
    ) external;

    function setReserveInterestRateStrategyAddress(
        uint256 reserveId,
        address rateStrategyAddress
    ) external;

    function burnLiquidity(uint256 reserveId, uint256 amount) external;

    function setConfiguration(
        uint256 reserveId,
        uint256 configuration
    ) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param reserveId The id of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(
        uint256 reserveId
    ) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param reserveId The id of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(
        uint256 reserveId
    ) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param reserveId The id of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(
        uint256 reserveId
    ) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param reserveId The id of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(
        uint256 reserveId
    ) external view returns (DataTypes.ReserveData memory);

    function getReservesList() external view returns (address[] memory);

    function getBorrowInfo(
        uint256 borrowId
    ) external view returns (DataTypes.BorrowInfo memory);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    function getReservesCount() external view returns (uint256);
}

interface IPriceOracle {
    function getPrice(address _nft) external returns (int);

    function getPrice_view(address _nft) external view returns (int);
}