// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/ISpoolOwner.sol";

/// @title Logic to help check whether the caller is the Spool owner
abstract contract SpoolOwnable {
    /// @notice Contract that checks if address is Spool owner
    ISpoolOwner internal immutable spoolOwner;

    /**
     * @notice Sets correct initial values
     * @param _spoolOwner Spool owner contract address
     */
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    /**
     * @notice Checks if caller is Spool owner
     * @return True if caller is Spool owner, false otherwise
     */
    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }


    /// @notice Checks and throws if caller is not Spool owner
    function _onlyOwner() private view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    /// @notice Checks and throws if caller is not Spool owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}