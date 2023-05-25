pragma solidity =0.6.6;

import "@openzeppelin/contracts/proxy/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/UpgradeableBeacon.sol";

contract OwnedBeaconProxy is BeaconProxy {
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event AdminChanged(address previousAdmin, address newAdmin);

    event BeaconUpgraded(address indexed beacon);

    modifier ifAdmin() {
        if (msg.sender == admin()) {
            _;
        } else {
            _fallback();
        }
    }

    constructor(address beacon, bytes memory data) public payable BeaconProxy(beacon, data) {
        emit BeaconUpgraded(beacon);
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        emit AdminChanged(address(0), msg.sender);
        _setAdmin(msg.sender);
    }

    function admin() public view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    function beacon() public view returns (address beacon_) {
        beacon_ = _beacon();
    }

    function implementation() public view returns (address implementation_) {
        implementation_ = _implementation();
    }

    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "OwnedBeaconProxy: new admin is the zero address");
        emit AdminChanged(admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    function upgradeBeaconTo(address newBeacon) external virtual ifAdmin {
        require(newBeacon != address(0), "OwnedBeaconProxy: new beacon is the zero address");
        emit BeaconUpgraded(newBeacon);
        _setBeacon(newBeacon, "");
    }

    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
    }
}