// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ACLTrait } from "../core/ACLTrait.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { RAY } from "../libraries/Constants.sol";
import { PercentageMath } from "../libraries/PercentageMath.sol";

import { IInterestRateModel } from "../interfaces/IInterestRateModel.sol";
import { IPoolService } from "../interfaces/IPoolService.sol";
import { ICreditManagerV2 } from "../interfaces/ICreditManagerV2.sol";

import { AddressProvider } from "../core/AddressProvider.sol";
import { DieselToken } from "../tokens/DieselToken.sol";
import { SECONDS_PER_YEAR, MAX_WITHDRAW_FEE } from "../libraries/Constants.sol";
import { Errors } from "../libraries/Errors.sol";

/// @title Pool Service Interface
/// @notice Implements business logic:
///   - Adding/removing pool liquidity
///   - Managing diesel tokens & diesel rates
///   - Taking/repaying Credit Manager debt
///
/// More: https://dev.gearbox.fi/developers/pools/pool-service
contract PoolService is IPoolService, ACLTrait, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;

    /// @dev Expected liquidity at last update (LU)
    uint256 public _expectedLiquidityLU;

    /// @dev The limit on expected (total) liquidity
    uint256 public override expectedLiquidityLimit;

    /// @dev Total borrowed amount
    /// @notice https://dev.gearbox.fi/developers/pools/economy/total-borrowed
    uint256 public override totalBorrowed;

    /// @dev Address provider
    AddressProvider public override addressProvider;

    /// @dev Interest rate model
    IInterestRateModel public interestRateModel;

    /// @dev The pool's underlying asset
    address public override underlyingToken;

    /// @dev Diesel(LP) token address
    address public immutable override dieselToken;

    /// @dev Map from Credit Manager addresses to the status of their ability to borrow
    mapping(address => bool) public override creditManagersCanBorrow;

    /// @dev Map from Credit Manager addresses to the status of their ability to repay
    mapping(address => bool) public creditManagersCanRepay;

    /// @dev The list of all Credit Managers
    address[] public override creditManagers;

    /// @dev Address of the protocol treasury
    address public treasuryAddress;

    /// @dev The cumulative interest index at last update
    uint256 public override _cumulativeIndex_RAY;

    /// @dev The current borrow rate
    /// @notice https://dev.gearbox.fi/developers/pools/economy#borrow-apy
    uint256 public override borrowAPY_RAY;

    /// @dev Timestamp of last update
    uint256 public override _timestampLU;

    /// @dev Withdrawal fee in PERCENTAGE FORMAT
    uint256 public override withdrawFee;

    /// @dev Contract version
    uint256 public constant override version = 1;

    //
    // CONSTRUCTOR
    //

    /// @dev Constructor
    /// @param _addressProvider Address provider
    /// @param _underlyingToken Address of the underlying token
    /// @param _interestRateModelAddress Address of the initial interest rate model
    constructor(
        address _addressProvider,
        address _underlyingToken,
        address _interestRateModelAddress,
        uint256 _expectedLiquidityLimit
    ) ACLTrait(_addressProvider) {
        require(
            _addressProvider != address(0) &&
                _underlyingToken != address(0) &&
                _interestRateModelAddress != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        addressProvider = AddressProvider(_addressProvider);

        underlyingToken = _underlyingToken;

        dieselToken = address(
            new DieselToken(
                string(
                    abi.encodePacked(
                        "diesel ",
                        IERC20Metadata(_underlyingToken).name()
                    )
                ),
                string(
                    abi.encodePacked(
                        "d",
                        IERC20Metadata(_underlyingToken).symbol()
                    )
                ),
                IERC20Metadata(_underlyingToken).decimals()
            )
        );

        treasuryAddress = addressProvider.getTreasuryContract();

        _timestampLU = block.timestamp;
        _cumulativeIndex_RAY = RAY; // T:[PS-5]
        _updateInterestRateModel(_interestRateModelAddress);
        expectedLiquidityLimit = _expectedLiquidityLimit;
    }

    //
    // LIQUIDITY MANAGEMENT
    //

    /**
     * @dev Adds liquidity to the pool
     * - Transfers the underlying asset from sender to the pool
     * - Mints diesel (LP) token фе current diesel rate
     * - Updates expected liquidity
     * - Updates borrow rate
     *
     * More: https://dev.gearbox.fi/developers/pools/pool-service#addliquidity
     *
     * @param amount Amount of tokens to be deposited
     * @param onBehalfOf The address that will receive the dToken
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without a facilitator.
     *
     * #if_succeeds {:msg "After addLiquidity() the pool gets the correct amoung of underlyingToken(s)"}
     *      IERC20(underlyingToken).balanceOf(address(this)) == old(IERC20(underlyingToken).balanceOf(address(this))) + amount;
     * #if_succeeds {:msg "After addLiquidity() onBehalfOf gets the right amount of dieselTokens"}
     *      IERC20(dieselToken).balanceOf(onBehalfOf) == old(IERC20(dieselToken).balanceOf(onBehalfOf)) + old(toDiesel(amount));
     * #if_succeeds {:msg "After addLiquidity() borrow rate decreases"}
     *      amount > 0 ==> borrowAPY_RAY <= old(currentBorrowRate());
     * #limit {:msg "Not more than 1 day since last borrow rate update"} block.timestamp <= _timestampLU + 3600 * 24;
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    )
        external
        override
        whenNotPaused // T:[PS-4]
        nonReentrant
    {
        require(onBehalfOf != address(0), Errors.ZERO_ADDRESS_IS_NOT_ALLOWED);

        require(
            expectedLiquidity() + amount <= expectedLiquidityLimit,
            Errors.POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT
        ); // T:[PS-31]

        uint256 balanceBefore = IERC20(underlyingToken).balanceOf(
            address(this)
        );

        IERC20(underlyingToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        ); // T:[PS-2, 7]

        amount =
            IERC20(underlyingToken).balanceOf(address(this)) -
            balanceBefore; // T:[FT-1]

        DieselToken(dieselToken).mint(onBehalfOf, toDiesel(amount)); // T:[PS-2, 7]

        _expectedLiquidityLU = _expectedLiquidityLU + amount; // T:[PS-2, 7]
        _updateBorrowRate(0); // T:[PS-2, 7]

        emit AddLiquidity(msg.sender, onBehalfOf, amount, referralCode); // T:[PS-2, 7]
    }

    /**
     * @dev Removes liquidity from pool
     * - Transfers to the sender the underlying amount equivalent to the passed Diesel amount
     * - Burns Diesel tokens
     * - Subtracts the removed underlying from expectedLiquidity
     * - Updates borrow rate
     *
     * More: https://dev.gearbox.fi/developers/pools/pool-service#removeliquidity
     *
     * @param amount Amount of Diesel tokens to burn
     * @param to Address to transfer the underlying to
     *
     * #if_succeeds {:msg "For removeLiquidity() sender must have sufficient diesel"}
     *      old(DieselToken(dieselToken).balanceOf(msg.sender)) >= amount;
     * #if_succeeds {:msg "After removeLiquidity() `to` gets the liquidity in underlyingToken(s)"}
     *      (to != address(this) && to != treasuryAddress) ==>
     *          IERC20(underlyingToken).balanceOf(to) == old(IERC20(underlyingToken).balanceOf(to) + (let t:= fromDiesel(amount) in t.sub(t.percentMul(withdrawFee))));
     * #if_succeeds {:msg "After removeLiquidity() treasury gets the withdraw fee in underlyingToken(s)"}
     *      (to != address(this) && to != treasuryAddress) ==>
     *          IERC20(underlyingToken).balanceOf(treasuryAddress) == old(IERC20(underlyingToken).balanceOf(treasuryAddress) + fromDiesel(amount).percentMul(withdrawFee));
     * #if_succeeds {:msg "After removeLiquidity() borrow rate increases"}
     *      (to != address(this) && amount > 0) ==> borrowAPY_RAY >= old(currentBorrowRate());
     * #limit {:msg "Not more than 1 day since last borrow rate update"} block.timestamp <= _timestampLU + 3600 * 24;
     */
    function removeLiquidity(uint256 amount, address to)
        external
        override
        whenNotPaused // T:[PS-4]
        nonReentrant
        returns (uint256)
    {
        require(to != address(0), Errors.ZERO_ADDRESS_IS_NOT_ALLOWED);

        uint256 underlyingTokensAmount = fromDiesel(amount); // T:[PS-3, 8]

        uint256 amountTreasury = underlyingTokensAmount.percentMul(withdrawFee);
        uint256 amountSent = underlyingTokensAmount - amountTreasury;

        IERC20(underlyingToken).safeTransfer(to, amountSent); // T:[PS-3, 34]

        if (amountTreasury > 0) {
            IERC20(underlyingToken).safeTransfer(
                treasuryAddress,
                amountTreasury
            );
        } // T:[PS-3, 34]

        DieselToken(dieselToken).burn(msg.sender, amount); // T:[PS-3, 8]

        _expectedLiquidityLU = _expectedLiquidityLU - underlyingTokensAmount; // T:[PS-3, 8]
        _updateBorrowRate(0); // T:[PS-3,8 ]

        emit RemoveLiquidity(msg.sender, to, amount); // T:[PS-3, 8]

        return amountSent;
    }

    /// @dev Returns expected liquidity - the amount of money that should be in the pool
    /// after all users close their Credit accounts and fully repay debts
    ///
    /// More: https://dev.gearbox.fi/developers/pools/economy#expected-liquidity
    function expectedLiquidity() public view override returns (uint256) {
        // timeDifference = blockTime - previous timeStamp
        uint256 timeDifference = block.timestamp - _timestampLU;

        //                                    currentBorrowRate * timeDifference
        //  interestAccrued = totalBorrow *  ------------------------------------
        //                                             SECONDS_PER_YEAR
        //
        uint256 interestAccrued = (totalBorrowed *
            borrowAPY_RAY *
            timeDifference) /
            RAY /
            SECONDS_PER_YEAR; // T:[PS-29]

        return _expectedLiquidityLU + interestAccrued; // T:[PS-29]
    }

    /// @dev Returns available liquidity in the pool (pool balance)
    /// More: https://dev.gearbox.fi/developers/
    function availableLiquidity() public view override returns (uint256) {
        return IERC20(underlyingToken).balanceOf(address(this));
    }

    //
    // CREDIT ACCOUNT LENDING
    //

    /// @dev Lends funds to a Credit Account and updates the pool parameters
    /// More: https://dev.gearbox.fi/developers/pools/pool-service#lendcreditAccount
    ///
    /// @param borrowedAmount Credit Account's debt principal
    /// @param creditAccount Credit Account's address
    ///
    /// #if_succeeds {:msg "After lendCreditAccount() borrow rate increases"}
    ///      borrowedAmount > 0 ==> borrowAPY_RAY >= old(currentBorrowRate());
    /// #limit {:msg "Not more than 1 day since last borrow rate update"} block.timestamp <= _timestampLU + 3600 * 24;
    function lendCreditAccount(uint256 borrowedAmount, address creditAccount)
        external
        override
        whenNotPaused // T:[PS-4]
    {
        require(
            creditManagersCanBorrow[msg.sender],
            Errors.POOL_CONNECTED_CREDIT_MANAGERS_ONLY
        ); // T:[PS-12, 13]

        // Transfer funds to credit account
        IERC20(underlyingToken).safeTransfer(creditAccount, borrowedAmount); // T:[PS-14]

        // Update borrow Rate
        _updateBorrowRate(0); // T:[PS-17]

        // Increase total borrowed amount
        totalBorrowed = totalBorrowed + borrowedAmount; // T:[PS-16]

        emit Borrow(msg.sender, creditAccount, borrowedAmount); // T:[PS-15]
    }

    /// @dev Registers Credit Account's debt repayment and updates parameters
    /// More: https://dev.gearbox.fi/developers/pools/pool-service#repaycreditAccount
    ///
    /// @param borrowedAmount Amount of principal ro repay
    /// @param profit The treasury profit from repayment
    /// @param loss Amount of underlying that the CA wan't able to repay
    /// @notice Assumes that the underlying (including principal + interest + fees)
    ///         was already transferred
    ///
    /// #if_succeeds {:msg "Cant have both profit and loss"} !(profit > 0 && loss > 0);
    /// #if_succeeds {:msg "After repayCreditAccount() if we are profitabe, or treasury can cover the losses, diesel rate doesn't decrease"}
    ///      (profit > 0 || toDiesel(loss) >= DieselToken(dieselToken).balanceOf(treasuryAddress)) ==> getDieselRate_RAY() >= old(getDieselRate_RAY());
    /// #limit {:msg "Not more than 1 day since last borrow rate update"} block.timestamp <= _timestampLU + 3600 * 24;
    function repayCreditAccount(
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    )
        external
        override
        whenNotPaused // T:[PS-4]
    {
        require(
            creditManagersCanRepay[msg.sender],
            Errors.POOL_CONNECTED_CREDIT_MANAGERS_ONLY
        ); // T:[PS-12]

        // For fee surplus we mint tokens for treasury
        if (profit > 0) {
            // T:[PS-22] provess that diesel rate will be the same within the margin of error
            DieselToken(dieselToken).mint(treasuryAddress, toDiesel(profit)); // T:[PS-21, 22]
            _expectedLiquidityLU = _expectedLiquidityLU + profit; // T:[PS-21, 22]
        }
        // If returned money < borrowed amount + interest accrued
        // it tries to compensate loss by burning diesel (LP) tokens
        // from treasury fund
        else {
            uint256 amountToBurn = toDiesel(loss); // T:[PS-19,20]

            uint256 treasuryBalance = DieselToken(dieselToken).balanceOf(
                treasuryAddress
            ); // T:[PS-19,20]

            if (treasuryBalance < amountToBurn) {
                amountToBurn = treasuryBalance;
                emit UncoveredLoss(
                    msg.sender,
                    loss - fromDiesel(treasuryBalance)
                ); // T:[PS-23]
            }

            // If treasury has enough funds, it just burns needed amount
            // to keep diesel rate on the same level
            DieselToken(dieselToken).burn(treasuryAddress, amountToBurn); // T:[PS-19, 20]

            //            _expectedLiquidityLU = _expectedLiquidityLU.sub(loss); //T:[PS-19,20]
        }

        // Update available liquidity
        _updateBorrowRate(loss); // T:[PS-19, 20, 21]

        // Reduce total borrowed. Should be after _updateBorrowRate() for correct calculations
        totalBorrowed -= borrowedAmount; // T:[PS-19, 20]

        emit Repay(msg.sender, borrowedAmount, profit, loss); // T:[PS-18]
    }

    //
    // INTEREST RATE MANAGEMENT
    //

    /**
     * @dev Calculates the most current value of the cumulative interest index
     *
     *                              /     currentBorrowRate * timeDifference \
     *  newIndex  = currentIndex * | 1 + ------------------------------------ |
     *                              \              SECONDS_PER_YEAR          /
     *
     * @return current cumulative index in RAY
     */
    function calcLinearCumulative_RAY() public view override returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp - _timestampLU; // T:[PS-28]

        return
            calcLinearIndex_RAY(
                _cumulativeIndex_RAY,
                borrowAPY_RAY,
                timeDifference
            ); // T:[PS-28]
    }

    /// @dev Calculates a new cumulative index value from the initial value, borrow rate and time elapsed
    /// @param cumulativeIndex_RAY Cumulative index at last update, in RAY
    /// @param currentBorrowRate_RAY Current borrow rate, in RAY
    /// @param timeDifference Time elapsed since last update, in seconds
    function calcLinearIndex_RAY(
        uint256 cumulativeIndex_RAY,
        uint256 currentBorrowRate_RAY,
        uint256 timeDifference
    ) public pure returns (uint256) {
        //                               /     currentBorrowRate * timeDifference \
        //  newIndex  = currentIndex *  | 1 + ------------------------------------ |
        //                               \              SECONDS_PER_YEAR          /
        //
        uint256 linearAccumulated_RAY = RAY +
            (currentBorrowRate_RAY * timeDifference) /
            SECONDS_PER_YEAR; // T:[GM-2]

        return (cumulativeIndex_RAY * linearAccumulated_RAY) / RAY; // T:[GM-2]
    }

    /// @dev Updates the borrow rate when liquidity parameters are changed
    /// @param loss The loss incurred by the pool on last parameter update, if any
    function _updateBorrowRate(uint256 loss) internal {
        // Update total _expectedLiquidityLU

        _expectedLiquidityLU = expectedLiquidity() - loss; // T:[PS-27]

        // Update cumulativeIndex
        _cumulativeIndex_RAY = calcLinearCumulative_RAY(); // T:[PS-27]

        // update borrow APY
        borrowAPY_RAY = interestRateModel.calcBorrowRate(
            _expectedLiquidityLU,
            availableLiquidity()
        ); // T:[PS-27]
        _timestampLU = block.timestamp; // T:[PS-27]
    }

    //
    // DIESEL TOKEN MGMT
    //

    /// @dev Returns the current exchange rate of Diesel tokens to underlying
    /// More info: https://dev.gearbox.fi/developers/pools/economy#diesel-rate
    function getDieselRate_RAY() public view override returns (uint256) {
        uint256 dieselSupply = IERC20(dieselToken).totalSupply();
        if (dieselSupply == 0) return RAY; // T:[PS-1]
        return (expectedLiquidity() * RAY) / dieselSupply; // T:[PS-6]
    }

    /// @dev Converts a quantity of the underlying to Diesel tokens
    /// @param amount Amount in underlyingToken tokens to be converted to diesel tokens
    function toDiesel(uint256 amount) public view override returns (uint256) {
        return (amount * RAY) / getDieselRate_RAY(); // T:[PS-24]
    }

    /// @dev Converts a quantity of Diesel tokens to the underlying
    /// @param amount Amount in diesel tokens to be converted to diesel tokens
    function fromDiesel(uint256 amount) public view override returns (uint256) {
        return (amount * getDieselRate_RAY()) / RAY; // T:[PS-24]
    }

    //
    // CONFIGURATION
    //

    /// @dev Connects a new Credit manager to pool
    /// @param _creditManager Address of the Credit Manager
    function connectCreditManager(address _creditManager)
        external
        configuratorOnly // T:[PS-9]
    {
        require(
            address(this) == ICreditManagerV2(_creditManager).poolService(),
            Errors.POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER
        ); // T:[PS-10]

        require(
            !creditManagersCanRepay[_creditManager],
            Errors.POOL_CANT_ADD_CREDIT_MANAGER_TWICE
        ); // T:[PS-35]

        creditManagersCanBorrow[_creditManager] = true; // T:[PS-11]
        creditManagersCanRepay[_creditManager] = true; // T:[PS-11]
        creditManagers.push(_creditManager); // T:[PS-11]
        emit NewCreditManagerConnected(_creditManager); // T:[PS-11]
    }

    /// @dev Forbids a Credit Manager to borrow
    /// @param _creditManager Address of the Credit Manager
    function forbidCreditManagerToBorrow(address _creditManager)
        external
        configuratorOnly // T:[PS-9]
    {
        creditManagersCanBorrow[_creditManager] = false; // T:[PS-13]
        emit BorrowForbidden(_creditManager); // T:[PS-13]
    }

    /// @dev Sets the new interest rate model for the pool
    /// @param _interestRateModel Address of the new interest rate model contract
    /// #limit {:msg "Disallow updating the interest rate model after the constructor"} address(interestRateModel) == address(0x0);
    function updateInterestRateModel(address _interestRateModel)
        public
        configuratorOnly // T:[PS-9]
    {
        _updateInterestRateModel(_interestRateModel);
    }

    /// @dev IMPLEMENTATION: updateInterestRateModel
    function _updateInterestRateModel(address _interestRateModel) internal {
        require(
            _interestRateModel != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        interestRateModel = IInterestRateModel(_interestRateModel); // T:[PS-25]
        _updateBorrowRate(0); // T:[PS-26]
        emit NewInterestRateModel(_interestRateModel); // T:[PS-25]
    }

    /// @dev Sets a new expected liquidity limit
    /// @param newLimit New expected liquidity limit
    function setExpectedLiquidityLimit(uint256 newLimit)
        external
        configuratorOnly // T:[PS-9]
    {
        expectedLiquidityLimit = newLimit; // T:[PS-30]
        emit NewExpectedLiquidityLimit(newLimit); // T:[PS-30]
    }

    /// @dev Sets a new withdrawal fee
    /// @param fee The new fee amount, in bp
    function setWithdrawFee(uint256 fee)
        public
        configuratorOnly // T:[PS-9]
    {
        require(fee <= MAX_WITHDRAW_FEE, Errors.POOL_INCORRECT_WITHDRAW_FEE); // T:[PS-32]
        withdrawFee = fee; // T:[PS-33]
        emit NewWithdrawFee(fee); // T:[PS-33]
    }

    /// @dev Returns the number of connected Credit Managers
    function creditManagersCount() external view override returns (uint256) {
        return creditManagers.length; // T:[PS-11]
    }
}