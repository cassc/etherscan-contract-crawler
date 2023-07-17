// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

abstract contract MessageBusAddress {
    /// @dev keccak256("exchange.rango.facets.cbridge.msg.messagebusaddress")
    bytes32 internal constant MSG_BUS_ADDRESS_NAMESPACE = hex"d82f4f572578dde7d9e798c168d6d6abab176a082ca20bc9a27a6c48782c92ef";

    struct MsgBusAddrStorage {
        address messageBus;
    }

    event MessageBusUpdated(address messageBus);

    function setMessageBusInternal(address _messageBus) internal {
        require(_messageBus != address(0), "Invalid Address messagebus");
        MsgBusAddrStorage storage s = getMsgBusAddrStorage();
        s.messageBus = _messageBus;
        emit MessageBusUpdated(s.messageBus);
    }

    function getMsgBusAddress() internal view returns (address) {
        MsgBusAddrStorage storage s = getMsgBusAddrStorage();
        return s.messageBus;
    }

    /// @dev fetch local storage
    function getMsgBusAddrStorage() private pure returns (MsgBusAddrStorage storage s) {
        bytes32 namespace = MSG_BUS_ADDRESS_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

}