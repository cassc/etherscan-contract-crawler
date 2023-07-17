// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @dev Error: fail to initialise timelock controller either attempting to initialise twice or
 * attempting to initialise with an invalid governor address.
 */
error FailToInitialiseTimelockController(bool initialised, address governor);

/**
 * @title DivaTimelockController Contract
 * @author ShamirLabs
 * @notice This contract is used to queue successful proposals.
 */
contract DivaTimelockController is TimelockController {
    bool private _initialised;

    constructor(
        uint256 minDelay
    )
        TimelockController(
            minDelay,
            new address[](0),
            new address[](0),
            msg.sender
        )
    {}

    // @dev This function has to be called after the contract is deployed to setup the
    // governance contract correctly.
    function initialiseAndRevokeAdminRole(
        address _governor
    ) external onlyRole(TIMELOCK_ADMIN_ROLE) {
        if (_initialised == false && _governor != address(0)) {
            _setupRole(EXECUTOR_ROLE, address(0)); // @dev grant EXECUTOR_ROLE to everyone
            _setupRole(PROPOSER_ROLE, _governor);
            _setupRole(CANCELLER_ROLE, address(this));

            _revokeRole(TIMELOCK_ADMIN_ROLE, _msgSender());

            _initialised = true;
        } else {
            revert FailToInitialiseTimelockController(_initialised, _governor);
        }
    }
}