// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./RoyaltiesReceiver.sol";

contract ReceiverFactory {

    event ReceiverCreated(
        address indexed creator,
        address instance,
        address[] payees, 
        uint256[] shares
    );

    /**
     * @dev Creates an instance of `RoyaltiesReceiver` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function deployReceiver(
        address[] memory payees, uint256[] memory shares_
    ) external returns (address) {
        RoyaltiesReceiver instance = new RoyaltiesReceiver();
        require(
            address(instance) != address(0),
            "Factory: INSTANCE_CREATION_FAILED"
        );
        instance.initialize(payees, shares_);
        emit ReceiverCreated(msg.sender, address(instance), payees, shares_);
        return address(instance);
    }

}