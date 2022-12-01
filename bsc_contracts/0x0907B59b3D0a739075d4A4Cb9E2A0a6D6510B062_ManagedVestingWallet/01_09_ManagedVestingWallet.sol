// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

import "./interfaces/IVestingManager.sol";

/**
 * @title ManagedVestingWallet
 * @dev This contract derived from @openzeppelin\VestingWallet and handles the vesting of Eth and ERC20 tokens for a given beneficiary.
 * Start and duration can be configured by VestingManager.
 */
contract ManagedVestingWallet is VestingWallet {

    address private immutable _vestingManager;

    constructor(address beneficiary_, address vestingManager_) VestingWallet(beneficiary_, type(uint64).max, type(uint64).max) {
        require(vestingManager_ != address(0), "ManagedVestingWallet: zero vesting manager address given");
        _vestingManager = vestingManager_;
    }

    receive() external payable virtual override { }

    function start() public view virtual override returns (uint256) {
        return IVestingManager(_vestingManager).start();
    }

    function duration() public view virtual override returns (uint256) {
        return IVestingManager(_vestingManager).duration();
    }
}