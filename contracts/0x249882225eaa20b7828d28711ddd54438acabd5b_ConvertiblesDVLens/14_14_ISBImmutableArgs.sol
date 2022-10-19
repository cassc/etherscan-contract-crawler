// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/interfaces/IConvertibleBondBox.sol";

interface ISBImmutableArgs {
    /**
     * @notice the lend slip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The lend slip object
     */
    function lendSlip() external pure returns (ISlip);

    /**
     * @notice the borrow slip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The borrowSlip object
     */
    function borrowSlip() external pure returns (ISlip);

    /**
     * @notice The convertible bond box object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The convertible bond box object
     */
    function convertibleBondBox() external pure returns (IConvertibleBondBox);

    /**
     * @notice The cnnvertible bond box object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The convertible bond box object
     */
    function initialPrice() external pure returns (uint256);

    /**
     * @notice The stable token used to buy bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The stable token object
     */

    function stableToken() external pure returns (IERC20);

    /**
     * @notice The safeTranche of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeTranche object
     */

    function safeTranche() external pure returns (ITranche);

    /**
     * @notice The address of the safeslip of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The address of the safeslip of the CBB
     */

    function safeSlipAddress() external pure returns (address);

    /**
     * @notice The tranche ratio of the safeTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the safeTranche of the CBB
     */

    function safeRatio() external pure returns (uint256);

    /**
     * @notice The riskTranche of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskTranche tranche object
     */

    function riskTranche() external pure returns (ITranche);

    /**
     * @notice The address of the riskSlip of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The address of the riskSlip of the CBB
     */

    function riskSlipAddress() external pure returns (address);

    /**
     * @notice The tranche ratio of the riskTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the riskTranche of the CBB
     */

    function riskRatio() external pure returns (uint256);

    /**
     * @notice The price granularity on the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The price granularity on the CBB
     */

    function priceGranularity() external pure returns (uint256);

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