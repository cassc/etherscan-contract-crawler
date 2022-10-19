// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/interfaces/ISlip.sol";
import "@buttonwood-protocol/tranche/contracts/interfaces/IBondController.sol";

interface ICBBImmutableArgs {
    /**
     * @notice The bond that holds the tranches
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The underlying buttonwood bond
     */
    function bond() external pure returns (IBondController);

    /**
     * @notice The safeSlip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeSlip Slip object
     */
    function safeSlip() external pure returns (ISlip);

    /**
     * @notice The riskSlip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskSlip Slip object
     */
    function riskSlip() external pure returns (ISlip);

    /**
     * @notice penalty for zslips
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The penalty ratio
     */
    function penalty() external pure returns (uint256);

    /**
     * @notice The rebasing collateral token used to make bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The rebasing collateral token object
     */
    function collateralToken() external pure returns (IERC20);

    /**
     * @notice The stable token used to buy bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The stable token object
     */
    function stableToken() external pure returns (IERC20);

    /**
     * @notice The tranche index used to pick a safe tranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The index representing the tranche
     */
    function trancheIndex() external pure returns (uint256);

    /**
     * @notice The maturity date of the underlying buttonwood bond
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The timestamp for the bond maturity
     */

    function maturityDate() external pure returns (uint256);

    /**
     * @notice The safeTranche of the Convertible Bond Box
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeTranche tranche object
     */

    function safeTranche() external pure returns (ITranche);

    /**
     * @notice The tranche ratio of the safeTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the safeTranche
     */

    function safeRatio() external pure returns (uint256);

    /**
     * @notice The riskTranche of the Convertible Bond Box
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskTranche tranche object
     */

    function riskTranche() external pure returns (ITranche);

    /**
     * @notice The tranche ratio of the riskTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the riskTranche
     */

    function riskRatio() external pure returns (uint256);

    /**
     * @notice The decimals of tranche-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of tranche-tokens
     */

    function trancheDecimals() external pure returns (uint256);

    /**
     * @notice The decimals of stable-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of stable-tokens
     */

    function stableDecimals() external pure returns (uint256);
}