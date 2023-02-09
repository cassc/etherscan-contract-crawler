// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeMiddleware } from "../../interfaces/ISubscribeMiddleware.sol";

/**
 * @title Subscribe Disallowed Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to disallow any subscriptions to the user.
 */
contract SubscribeDisallowedMw is ISubscribeMiddleware {
    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISubscribeMiddleware
    function setSubscribeMwData(uint256, bytes calldata)
        external
        pure
        override
        returns (bytes memory)
    {
        // do nothing
        return new bytes(0);
    }

    /**
     * @inheritdoc ISubscribeMiddleware
     * @notice Process that disallows a subscription
     */
    function preProcess(
        uint256,
        address,
        address,
        bytes calldata
    ) external pure override {
        revert("SUBSCRIBE_DISALLOWED");
    }

    /// @inheritdoc ISubscribeMiddleware
    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscribeNFT,
        bytes calldata data
    ) external override {
        // do nothing
    }
}