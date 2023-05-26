// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BridgeStore is Ownable {
    address private _bridge;

    event SetBridge(address indexed oldBridge, address indexed newBridge);

    /// @notice Sets bridge address.
    ///
    /// @notice Emits a {SetBridge} event.
    function setBridge(address newBridge) public onlyOwner {
        emit SetBridge(_bridge, newBridge);
        // slither-disable-next-line missing-zero-check
        _bridge = newBridge;
    }

    function getBridge() public view returns (address) {
        return _bridge;
    }
}