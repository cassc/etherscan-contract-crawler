// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

/**
 * @title Collect Disallowed Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to disallow any collection to the essence that uses it.
 */
contract CollectDisallowedMw is IEssenceMiddleware {
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssenceMiddleware
    function setEssenceMwData(
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes memory) {
        // do nothing
        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice This process denies any attempts to collect the essence
     */
    function preProcess(
        uint256,
        uint256,
        address,
        address,
        bytes calldata
    ) external pure override {
        revert("COLLECT_DISALLOWED");
    }

    /// @inheritdoc IEssenceMiddleware
    function postProcess(
        uint256,
        uint256,
        address,
        address,
        bytes calldata
    ) external {
        // do nothing
    }
}