// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {CliffVestingWallet} from "./CliffVestingWallet.sol";

contract VestingWalletFactory {
    event CreateVesting(address indexed addr);

    CliffVestingWallet public immutable impl;

    constructor() {
        CliffVestingWallet _impl = new CliffVestingWallet();
        _impl.initialize(address(this), 0, 0, 0);
        impl = _impl;
    }

    /// @notice Create a vesting wallet contract
    /// @dev Emits a CreateVesting event with address of the wallet
    /// @param _beneficiary the address that will receive vesting tokens or eth
    /// @param _startTimestamp the timestamp when vesting starts
    /// @param _durationSeconds duration of vesting in seconds
    /// @param _cliffSeconds cliff, before which no vesting occurs. If 0, no cliff is used.
    function createVestingWallet(
        address _beneficiary,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        uint64 _cliffSeconds
    ) public {
        CliffVestingWallet clone = CliffVestingWallet(
            payable(Clones.clone(address(impl)))
        );
        clone.initialize(
            _beneficiary,
            _startTimestamp,
            _durationSeconds,
            _cliffSeconds
        );
        emit CreateVesting(address(clone));
    }
}