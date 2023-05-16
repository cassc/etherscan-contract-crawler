// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Clones.sol";
import { EIP2981RoyaltyOverrideCloneable } from "./RoyaltyOverrideCloneable.sol";
import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from "./MultiReceiverRoyaltyOverrideCloneable.sol";
import { Recipient } from "./IRoyaltySplitter.sol";

/**
 * Clone Factory for EIP2981 reference override implementation
 */
contract EIP2981RoyaltyOverrideFactoryEZ {
    address public immutable SINGLE_RECIPIENT_ORIGIN_ADDRESS;
    address public immutable MULTI_RECIPIENT_ORIGIN_ADDRESS;
    address payable public immutable ROYALTY_SPLITTER_ORIGIN_ADDRESS;

    error InvalidRoyaltyRegistryAddress();

    uint256 constant INVALID_ROYALTY_REGISTRY_ADDRESS_SELECTOR = 0x1c491d3;

    event EIP2981RoyaltyOverrideCreated(address newEIP2981RoyaltyOverride);

    constructor(address singleOrigin, address multiOrigin, address payable royaltySplitterOrigin) {
        SINGLE_RECIPIENT_ORIGIN_ADDRESS = singleOrigin;
        MULTI_RECIPIENT_ORIGIN_ADDRESS = multiOrigin;
        ROYALTY_SPLITTER_ORIGIN_ADDRESS = royaltySplitterOrigin;
    }


    function createOverrideAndRegister(
        address royaltyRegistry,
        address tokenAddress,
        uint16 defaultBps,
        Recipient[] calldata defaultRecipients
    ) public returns (address) {
        address clone = Clones.clone(MULTI_RECIPIENT_ORIGIN_ADDRESS);
        EIP2981MultiReceiverRoyaltyOverrideCloneable(clone).initialize(
            ROYALTY_SPLITTER_ORIGIN_ADDRESS, defaultBps, defaultRecipients, msg.sender
        );
        emit EIP2981RoyaltyOverrideCreated(clone);
        return clone;
    }


}