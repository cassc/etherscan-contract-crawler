// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IPoolFactory.sol";
import "../interfaces/IFeesManager.sol";
import "../interfaces/IGenericPool.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IOracle.sol";
import "./Types.sol";

library GenericUtils {
    using SafeERC20 for IERC20;

    uint256 internal constant HUNDRED_PERCENT = 100_0000;
    bytes32 private constant APPROVE_LEND = 0x1000000000000000000000000000000000000000000000000000000000000000; //1<<255
    bytes32 private constant APPROVE_COL = 0x0100000000000000000000000000000000000000000000000000000000000000; //2<<255
    bytes32 private constant APPROVE_LEND_STRATEGY = 0x0010000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant APPROVE_COL_STRATEGY = 0x0001000000000000000000000000000000000000000000000000000000000000;
   
    /* ========== EVENTS ========== */
    event BalanceChange(address token, address to, bool incoming, uint256 amount);

    /* ========== ERRORS ========== */
    error OracleNotSet();

    /* ========== FUNCTIONS ========== */
    
    /// @notice                Makes required strategy approvals based off whether the collateral or lend token is being used.
    /// @param _strategy       The key used with the strategy.
    /// @param _lendToken      The address of lend token being used. 
    /// @param _colToken      The address of collateral token being used. 
    function initiateStrategy(bytes32 _strategy, IERC20 _lendToken, IERC20 _colToken) external returns (
        IStrategy strategy
    ){
        address strategyAddress = address(uint160(uint256(_strategy)));
        strategy = IStrategy(strategyAddress);
        // Allow strategy to manage the lend vault tokens on behalf of the pool. Useful with strategies that wrap EIP4626 vaults.
        if ((_strategy & APPROVE_LEND_STRATEGY) == APPROVE_LEND_STRATEGY) {
            IERC20(IStrategy(strategyAddress).getDestination()).approve(strategyAddress, type(uint256).max);
        } 
        if ((_strategy & APPROVE_COL_STRATEGY) == APPROVE_COL_STRATEGY) {
            IERC20(IStrategy(strategyAddress).getDestination()).approve(strategyAddress, type(uint256).max);
        }
        if ((_strategy & APPROVE_LEND) == APPROVE_LEND) {
            _lendToken.approve(strategyAddress, type(uint256).max);
        } 
        if ((_strategy & APPROVE_COL) == APPROVE_COL) {
            _colToken.approve(strategyAddress, type(uint256).max);
        }
    }
  
    /// @notice                  Check if col price is valid based off of LTV requirement
    /// @dev                     We need to ensure that 1 unit of collateral is worth more than what 1 unit of collateral allows to borrow
    /// @param _priceFeed        Address of the oracle to use
    /// @param _colToken         Address of the collateral token
    /// @param _lendToken        Address of the lend token
    /// @param _mintRatio        Mint ratio of the pool
    /// @param _ltv              Dictated as minLTV or maxLTV dependent on _poolType
    /// @param _poolType         The type of pool calling this function
    function isValidPrice(
        IOracle _priceFeed,
        IERC20 _colToken,
        IERC20 _lendToken,
        uint256 _mintRatio,
        uint48 _ltv,
        PoolType _poolType
    ) external view returns (bool) {
        if (address(_priceFeed) == address(0)) revert OracleNotSet();
        int256 priceLend = _priceFeed.getPriceUSD(address(_lendToken));
        int256 priceCol = _priceFeed.getPriceUSD(address(_colToken));
        if (priceLend > 0 && priceCol > 0) { // Check that -1 or other invalid value was not returned for both assets
            if (_poolType == PoolType.LENDING_ONE_TO_MANY) {
                uint256 maxLendValue = (uint256(priceCol) * _ltv) / HUNDRED_PERCENT;
                return maxLendValue >= ((_mintRatio * uint256(priceLend)) / 1e18);
            } else if (_poolType == PoolType.BORROWING_ONE_TO_MANY) {
                uint256 minLendValue = (uint256(priceCol) * _ltv) / HUNDRED_PERCENT;
                return minLendValue <= ((_mintRatio * uint256(priceLend)) / 1e18);
            }
        }
        return false;
    }

    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _mintRatio           MintRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    // Amount of collateral to return is always computed as:
    //                                 lendTokenAmount
    // amountOfCollateralReturned  =   ---------------
    //                                    mintRatio
    // 
    // We also need to ensure that the correct amount of decimals are used. Output should always be in
    // collateral token decimals.
    function computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _mintRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) external view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_mintRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _mintRatio;
        }
    }

    /// @notice               Used when xfering tokens to an address from a pool.
    /// @param _token         Address of token that is to be xfered.
    /// @param _account       Address to send tokens to.
    /// @param _amount        Amount of tokens to xfer.
    function safeTransfer(
        IERC20 _token,
        address _account,
        uint256 _amount
    ) external{
        if (_amount > 0){
            _token.safeTransfer(_account, _amount);
            emit BalanceChange(address(_token), _account, false, _amount);
        }
    }

    /// @notice              Used when xfering tokens on an addresses behalf. Approval must be done in a seperate transaction.
    /// @param _token        Address of token that is to be xfered.
    /// @param _from         Address of the sender.
    /// @param _to           Address of the recipient.
    /// @param _amount       Amount of tokens to xfer.
    /// @return received     Actual amount of tokens that _to receives.
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256 received){
        if (_amount > 0){
            uint256 initialBalance = _token.balanceOf(_to);
            _token.safeTransferFrom(_from, _to, _amount);
            received = _token.balanceOf(_to) - initialBalance;
            emit BalanceChange(address(_token), _to, true, received);
        }
    }
}