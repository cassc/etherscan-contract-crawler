// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VestingWallet.sol";

import "./interfaces/IVestingManager.sol";

/**
 * @title ManagedVestingWallet
 * @dev This contract derived from @openzeppelin\VestingWallet and handles the vesting of Eth and ERC20 tokens for a given beneficiary.
 * Start and duration can be configured by VestingManager.
 */
contract ManagedVestingWallet is VestingWallet {

    address private _vestingManager;
    address private _beneficiary;

    address private immutable _factory;

    modifier onlyFactory {
        require(_factory == msg.sender, "ManagedVestingWallet: only factory");
        _;
    }

    constructor() {
        _factory = msg.sender;
    }

    function start() public view virtual override returns (uint256) {
        return IVestingManager(_vestingManager).start();
    }

    function duration() public view virtual override returns (uint256) {
        return IVestingManager(_vestingManager).duration();
    }

    function beneficiary() public view virtual override returns (address) {
        return _beneficiary;
    }

    function vestingManager() public view returns (address) {
        return _vestingManager;
    }

    function initialize(address beneficiary_, address vestingManager_) public onlyFactory returns (bool) {
        require(vestingManager_ != address(0), "ManagedVestingWallet: vesting manager is zero address");
        require(beneficiary_ != address(0), "ManagedVestingWallet: beneficiary is zero address");
        _vestingManager = vestingManager_;
        _beneficiary = beneficiary_;
        return true;
    }
}