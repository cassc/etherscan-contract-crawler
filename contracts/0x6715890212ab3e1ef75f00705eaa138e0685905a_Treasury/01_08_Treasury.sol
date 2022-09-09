//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "../upgrade/FsBase.sol";

/// @notice `Treasury` gets a fraction of trading fees. We don't have a good use case for the funds
/// accumulated here yet, so in the meantime, `enact` allows arbitrary usage.
/// This is a proxied contract using the Initializable pattern, so no constructor should be added.
contract Treasury is FsBase {
    event EnactTreasury(address target, bytes data);

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    ///      When adding new fields to this contract, one must decrement this counter proportional to the
    ///      number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[1000] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    function initialize() external initializer {
        initializeFsOwnable();
    }

    /// @notice Executes an arbitrary method in the `target` address.
    /// @param target Address of the contract to call.
    /// @param data Encoded Ethereum contract call.
    function enact(address target, bytes memory data) external onlyOwner {
        emit EnactTreasury(target, data);
        //slither-disable-next-line unused-return
        Address.functionCall(target, data);
    }
}