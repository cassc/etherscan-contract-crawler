// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @title MetaRouterGateway
 * @notice During the `metaRoute` transaction `MetaRouter` (only) claims user's tokens
 * from `MetaRoutetGateway` contract and then operates with them.
 */
contract MetaRouterGateway {
    address public immutable metaRouter;

    modifier onlyMetarouter() {
        require(metaRouter == msg.sender, "Symb: caller is not the metarouter");
        _;
    }

    constructor(address _metaRouter) {
        metaRouter = _metaRouter;
    }

    function claimTokens(
        address _token,
        address _from,
        uint256 _amount
    ) external onlyMetarouter {
        TransferHelper.safeTransferFrom(_token, _from, metaRouter, _amount);
    }
}