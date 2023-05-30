//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import {Part} from "../interfaces/IAvatar.sol";

struct Props {
    uint256 davaId;
    mapping(bytes32 => Part) parts;
}

contract MinimalProxy is Initializable, Proxy, ERC1967Upgrade {
    bytes32 internal constant DAVA_CONTRACT_SLOT =
        bytes32(uint256(keccak256("dava.contract")) - 1);
    bytes32 internal constant PROPS_SLOT =
        bytes32(uint256(keccak256("dava.props.v1")) - 1);

    function initialize(uint256 davaId_) public virtual initializer {
        _upgradeBeaconToAndCall(msg.sender, "", false);
        StorageSlot.getAddressSlot(DAVA_CONTRACT_SLOT).value = msg.sender;
        _props().davaId = davaId_;
    }

    function _props() internal pure virtual returns (Props storage r) {
        bytes32 slot = PROPS_SLOT;
        assembly {
            r.slot := slot
        }
    }

    // See openzeppelin's BeaconProxy.sol

    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeacon(_getBeacon()).implementation();
    }

    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}