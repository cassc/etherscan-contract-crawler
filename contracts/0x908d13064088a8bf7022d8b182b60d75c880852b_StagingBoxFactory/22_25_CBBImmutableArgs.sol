// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "clones-with-immutable-args/Clone.sol";
import "../src/interfaces/ISlip.sol";
import "./ICBBImmutableArgs.sol";

/**
 * @notice Defines the immutable arguments for a CBB
 * @dev using the clones-with-immutable-args library
 * we fetch args from the code section
 */
contract CBBImmutableArgs is Clone, ICBBImmutableArgs {
    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function bond() public pure override returns (IBondController) {
        return IBondController(_getArgAddress(0));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function safeSlip() public pure override returns (ISlip) {
        return ISlip(_getArgAddress(20));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function riskSlip() public pure override returns (ISlip) {
        return ISlip(_getArgAddress(40));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function penalty() public pure override returns (uint256) {
        return _getArgUint256(60);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function collateralToken() public pure override returns (IERC20) {
        return IERC20(_getArgAddress(92));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function stableToken() public pure override returns (IERC20) {
        return IERC20(_getArgAddress(112));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function trancheIndex() public pure override returns (uint256) {
        return _getArgUint256(132);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function maturityDate() public pure override returns (uint256) {
        return _getArgUint256(164);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function safeTranche() public pure override returns (ITranche) {
        return ITranche(_getArgAddress(196));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function safeRatio() public pure override returns (uint256) {
        return _getArgUint256(216);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function riskTranche() public pure override returns (ITranche) {
        return ITranche(_getArgAddress(248));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function riskRatio() public pure override returns (uint256) {
        return _getArgUint256(268);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function trancheDecimals() public pure override returns (uint256) {
        return _getArgUint256(300);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function stableDecimals() public pure override returns (uint256) {
        return _getArgUint256(332);
    }
}