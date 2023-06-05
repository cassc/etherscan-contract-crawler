//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './INFModule.sol';

interface INFModuleWithEvents is INFModule {
    enum Events {
        MINT,
        TRANSFER,
        BURN
    }

    /// @dev callback received from a contract when an event happens
    /// @param eventType the type of event fired
    /// @param tokenId the token for which the id is fired
    /// @param from address from
    /// @param to address to
    function onEvent(
        Events eventType,
        uint256 tokenId,
        address from,
        address to
    ) external;
}