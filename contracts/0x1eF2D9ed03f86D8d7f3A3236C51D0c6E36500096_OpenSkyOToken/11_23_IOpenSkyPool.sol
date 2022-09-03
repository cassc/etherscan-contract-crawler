// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyPool
 * @author OpenSky Labs
 * @notice Defines the basic interface for an OpenSky Pool.
 **/

interface IOpenSkyPool {
    /*
     * @dev Emitted on create()
     * @param reserveId The ID of the reserve
     * @param underlyingAsset The address of the underlying asset
     * @param oTokenAddress The address of the oToken
     * @param name The name to use for oToken
     * @param symbol The symbol to use for oToken
     * @param decimals The decimals of the oToken
     */
    event Create(
        uint256 indexed reserveId,
        address indexed underlyingAsset,
        address indexed oTokenAddress,
        string name,
        string symbol,
        uint8 decimals
    );

    /*
     * @dev Emitted on setTreasuryFactor()
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     */
    event SetTreasuryFactor(uint256 indexed reserveId, uint256 factor);

    /*
     * @dev Emitted on setInterestModelAddress()
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The address of the interest model contract
     */
    event SetInterestModelAddress(uint256 indexed reserveId, address interestModelAddress);

    /*
     * @dev Emitted on openMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event OpenMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on closeMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event CloseMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on deposit()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive the oTokens
     * @param amount The amount of ETH to be deposited
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     * 0 if the action is executed directly by the user, without any intermediaries
     */
    event Deposit(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount, uint256 referralCode);

    /*
     * @dev Emitted on withdraw()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive assets withdrawed
     * @param amount The amount to be withdrawn
     */
    event Withdraw(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);

    /*
     * @dev Emitted on borrow()
     * @param reserveId The ID of the reserve
     * @param user The address initiating the withdrawal(), owner of oTokens
     * @param onBehalfOf The address that will receive the ETH and the loan NFT
     * @param loanId The loan ID
     */
    event Borrow(
        uint256 indexed reserveId,
        address user,
        address indexed onBehalfOf,
        uint256 indexed loanId
    );

    /*
     * @dev Emitted on repay()
     * @param reserveId The ID of the reserve
     * @param repayer The address initiating the repayment()
     * @param onBehalfOf The address that will receive the pledged NFT
     * @param loanId The ID of the loan
     * @param repayAmount The borrow balance of the loan when it was repaid
     * @param penalty The penalty of the loan for either early or overdue repayment
     */
    event Repay(
        uint256 indexed reserveId,
        address repayer,
        address indexed onBehalfOf,
        uint256 indexed loanId,
        uint256 repayAmount,
        uint256 penalty
    );

    /*
     * @dev Emitted on extend()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The owner address of loan NFT
     * @param oldLoanId The ID of the old loan
     * @param newLoanId The ID of the new loan
     */
    event Extend(uint256 indexed reserveId, address indexed onBehalfOf, uint256 oldLoanId, uint256 newLoanId);

    /*
     * @dev Emitted on startLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator The address initiating startLiquidation()
     */
    event StartLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator
    );

    /*
     * @dev Emitted on endLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator
     * @param repayAmount The amount used to repay, must be equal to or greater than the borrowBalance, excess part will be shared by all the lenders
     * @param borrowBalance The borrow balance of the loan
     */
    event EndLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator,
        uint256 repayAmount,
        uint256 borrowBalance
    );

    /**
     * @notice Creates a reserve
     * @dev Only callable by the pool admin role
     * @param underlyingAsset The address of the underlying asset
     * @param name The name of the oToken
     * @param symbol The symbol for the oToken
     * @param decimals The decimals of the oToken
     **/
    function create(
        address underlyingAsset,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Updates the treasury factor of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     **/
    function setTreasuryFactor(uint256 reserveId, uint256 factor) external;

    /**
     * @notice Updates the interest model address of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The new address of the interest model contract
     **/
    function setInterestModelAddress(uint256 reserveId, address interestModelAddress) external;

    /**
     * @notice Open the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function openMoneyMarket(uint256 reserveId) external;

    /**
     * @notice Close the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function closeMoneyMarket(uint256 reserveId) external;

    /**
     * @dev Deposits ETH into the reserve.
     * @param reserveId The ID of the reserve
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     **/
    function deposit(uint256 reserveId, uint256 amount, address onBehalfOf, uint256 referralCode) external;

    /**
     * @dev withdraws the ETH from reserve.
     * @param reserveId The ID of the reserve
     * @param amount amount of oETH to withdraw and receive native ETH
     **/
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf) external;

    /**
     * @dev Borrows ETH from reserve using an NFT as collateral and will receive a loan NFT as receipt.
     * @param reserveId The ID of the reserve
     * @param amount amount of ETH user will borrow
     * @param duration The desired duration of the loan
     * @param nftAddress The collateral NFT address
     * @param tokenId The ID of the NFT
     * @param onBehalfOf address of the user who will receive ETH and loan NFT.
     **/
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Repays a loan, as a result the corresponding loan NFT owner will receive the collateralized NFT.
     * @param loanId The ID of the loan the user will repay
     */
    function repay(uint256 loanId) external returns (uint256);

    /**
     * @dev Extends creates a new loan and terminates the old loan.
     * @param loanId The loan ID to extend
     * @param amount The amount of ERC20 token the user will borrow in the new loan
     * @param duration The selected duration the user will borrow in the new loan
     * @param onBehalfOf The address will borrow in the new loan
     **/
    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration,
        address onBehalfOf
    ) external returns (uint256, uint256);

    /**
     * @dev Starts liquidation for a loan when it's in LIQUIDATABLE status
     * @param loanId The ID of the loan which will be liquidated
     */
    function startLiquidation(uint256 loanId) external;

    /**
     * @dev Completes liquidation for a loan which will be repaid.
     * @param loanId The ID of the liquidated loan that will be repaid.
     * @param amount The amount of the token that will be repaid.
     */
    function endLiquidation(uint256 loanId, uint256 amount) external;

    /**
     * @dev Returns the state of the reserve
     * @param reserveId The ID of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(uint256 reserveId) external view returns (DataTypes.ReserveData memory);

    /**
     * @dev Returns the normalized income of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the remaining liquidity of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's withdrawable balance
     */
    function getAvailableLiquidity(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the instantaneous borrow limit value of a special NFT
     * @param nftAddress The address of the NFT
     * @param tokenId The ID of the NFT
     * @return The NFT's borrow limit
     */
    function getBorrowLimitByOracle(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @dev Returns the sum of all users borrow balances include borrow interest accrued
     * @param reserveId The ID of the reserve
     * @return The total borrow balance of the reserve
     */
    function getTotalBorrowBalance(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns TVL (total value locked) of the reserve.
     * @param reserveId The ID of the reserve
     * @return The reserve's TVL
     */
    function getTVL(uint256 reserveId) external view returns (uint256);
}