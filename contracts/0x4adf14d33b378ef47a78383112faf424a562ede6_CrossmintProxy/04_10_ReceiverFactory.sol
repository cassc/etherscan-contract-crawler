// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./CloneFactory.sol";
import "./Receiver.sol";
import "./IReceiver.sol";

abstract contract ReceiverFactory is CloneFactory {
    Receiver internal _receiver;
    address private immutable _owner;

    constructor(address owner_) {
        _owner = owner_;
        _receiver = new Receiver();
    }

    function deployReceiver() internal returns (address) {
        address clone = createClone(address(_receiver));
        IReceiver(clone).init(_owner);
        return clone;
    }
}