/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "../lib/Facts.sol";

/**
 * @title IRelicReceiver
 * @author Theori, Inc.
 * @notice IRelicReceiver has callbacks to receives ephemeral facts from Relic
 */
interface IRelicReceiver {
    /**
     * @notice receives an ephemeral fact from Relic
     * @param initiator the account which initiated the fact proving
     * @param fact the proven fact information
     * @param data extra data passed from the initiator - this data may come
     *        from untrusted parties and thus should be validated
     */
    function receiveFact(
        address initiator,
        Fact calldata fact,
        bytes calldata data
    ) external;
}