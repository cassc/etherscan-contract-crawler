// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { IPoolFactory } from '../interfaces/pool/IPoolFactory.sol';
import { IERC20Token }  from '../interfaces/pool/IPool.sol';

/**
 *  @title  Pool Deployer base contract
 *  @notice Base contract for Pool Deployer, contains logic used by both ERC20 and ERC721 Pool Factories.
 */
abstract contract PoolDeployer {

    /// @dev Min interest rate value allowed for deploying the pool (1%)
    uint256 public constant MIN_RATE = 0.01 * 1e18;
    /// @dev Max interest rate value allowed for deploying the pool (10%)
    uint256 public constant MAX_RATE = 0.1  * 1e18;

    /// @dev `Ajna` token address
    address public ajna; // Ajna token contract address on a network.

    /***********************/
    /*** State Variables ***/
    /***********************/

    /// @dev SubsetHash => CollateralAddress => QuoteAddress => Pool Address mapping
    // slither-disable-next-line uninitialized-state
    mapping(bytes32 => mapping(address => mapping(address => address))) public deployedPools;

    /// @notice List of all deployed pools. Separate list is maintained for each factory.
    // slither-disable-next-line uninitialized-state
    address[] public deployedPoolsList;

    /*****************/
    /*** Modifiers ***/
    /*****************/

    /**
     * @notice Ensures that pools are deployed according to specifications.
     * @dev    Used by both `ERC20` and `ERC721` pool factories.
     */
    modifier canDeploy(address collateral_, address quote_, uint256 interestRate_) {
        if (collateral_ == quote_)                                  revert IPoolFactory.DeployQuoteCollateralSameToken();
        if (collateral_ == address(0) || quote_ == address(0))      revert IPoolFactory.DeployWithZeroAddress();
        if (MIN_RATE > interestRate_ || interestRate_ > MAX_RATE)   revert IPoolFactory.PoolInterestRateInvalid();
        _;
    }

    /*********************************/
    /*** Internal Helper Functions ***/
    /*********************************/

    /**
     * @notice Calculates `ERC20` token scale based on token decimals.
     * @dev    Reverts with `DecimalsNotCompliant` if token decimals are more than 18 or token contract lacks `decimals` method.
     * @param  token_  `ERC20` token address.
     * @return scale_  Calculated token scale. 
     */
    function _getTokenScale(address token_) internal view returns (uint256 scale_) {
        try IERC20Token(token_).decimals() returns (uint8 tokenDecimals_) {
            // revert if token decimals is more than 18
            if (tokenDecimals_ > 18) revert IPoolFactory.DecimalsNotCompliant();

            // scale calculated at pool precision (18)
            scale_ = 10 ** (18 - tokenDecimals_);
        } catch {
            // revert if token contract lack `decimals` method
            revert IPoolFactory.DecimalsNotCompliant();
        }
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    /**
     * @notice Returns the list of all deployed pools.
     * @dev    This function is used by integrations to access deployed pools.
     * @dev    Each factory implementation maintains its own list of deployed pools.
     * @return List of all deployed pools.
     */
    function getDeployedPoolsList() external view returns (address[] memory) {
        return deployedPoolsList;
    }

    /**
     * @notice Returns the number of deployed pools that have been deployed by a factory.
     * @return Length of `deployedPoolsList` array.
     */
    function getNumberOfDeployedPools() external view returns (uint256) {
        return deployedPoolsList.length;
    }
}