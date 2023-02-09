// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

import { ISubscribeMiddleware } from "../../interfaces/ISubscribeMiddleware.sol";

/**
 * @title Subscribe Only Once Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow the address to subscribe only once to another address.
 */
contract SubscribeOnlyOnceMw is ISubscribeMiddleware {
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
     * @notice Process that checks if the subscriber is already subscribed.
     */
    function preProcess(
        uint256,
        address subscriber,
        address subscribeNFT,
        bytes calldata
    ) external view override {
        require(
            ERC721(subscribeNFT).balanceOf(subscriber) == 0,
            "Already subscribed"
        );
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