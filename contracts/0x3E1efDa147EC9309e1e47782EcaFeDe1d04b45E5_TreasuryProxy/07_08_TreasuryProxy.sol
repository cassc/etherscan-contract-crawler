// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./interface/IAzimuth.sol";

contract TreasuryProxy is ERC1967Proxy {
    IAzimuth immutable azimuth;

    bytes32 constant FROZEN_SLOT = bytes32(uint256(keccak256("TreasuryProxy.frozen")) - 1);

    event Froze(address frozenImplementation);

    constructor(IAzimuth _azimuth, address _impl) ERC1967Proxy(_impl, "") {
        azimuth = _azimuth;
    }

    modifier ifEcliptic() {
        require(msg.sender == azimuth.owner(), "TreasuryProxy: Only Ecliptic");
        _;
    }

    function _frozen() internal pure returns (StorageSlot.BooleanSlot storage) {
        return StorageSlot.getBooleanSlot(FROZEN_SLOT);
    }

    modifier notFrozen() {
        require(!_frozen().value, "TreasuryProxy: Contract frozen");
        _;
    }

    function upgradeTo(address _impl) external ifEcliptic notFrozen returns (bool) {
        _upgradeTo(_impl);
        return true;
    }

    function upgradeToAndCall(address _impl, bytes calldata data, bool forceCall)
        external ifEcliptic notFrozen returns (bool)
    {
        _upgradeToAndCall(_impl, data, forceCall);
        return true;
    }
    
    function freeze() external ifEcliptic notFrozen returns (bool) {
        _frozen().value = true;
        emit Froze(_implementation());
        return true;
    }
}