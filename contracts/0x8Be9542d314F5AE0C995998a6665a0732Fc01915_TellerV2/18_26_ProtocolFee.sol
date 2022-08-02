pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ProtocolFee is OwnableUpgradeable {
    // Protocol fee set for loan processing.
    uint16 private _protocolFee;

    /**
     * @notice This event is emitted when the protocol fee has been updated.
     * @param newFee The new protocol fee set.
     * @param oldFee The previously set protocol fee.
     */
    event ProtocolFeeSet(uint16 newFee, uint16 oldFee);

    /**
     * @notice Initialized the protocol fee.
     * @param initFee The initial protocol fee to be set on the protocol.
     */
    function __ProtocolFee_init(uint16 initFee) internal onlyInitializing {
        __Ownable_init();
        __ProtocolFee_init_unchained(initFee);
    }

    function __ProtocolFee_init_unchained(uint16 initFee)
        internal
        onlyInitializing
    {
        setProtocolFee(initFee);
    }

    /**
     * @notice Returns the current protocol fee.
     */
    function protocolFee() public view virtual returns (uint16) {
        return _protocolFee;
    }

    /**
     * @notice Lets the DAO/owner of the protocol to set a new protocol fee.
     * @param newFee The new protocol fee to be set.
     */
    function setProtocolFee(uint16 newFee) public virtual onlyOwner {
        // Skip if the fee is the same
        if (newFee == _protocolFee) return;

        uint16 oldFee = _protocolFee;
        _protocolFee = newFee;
        emit ProtocolFeeSet(newFee, oldFee);
    }
}