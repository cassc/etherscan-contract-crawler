// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MARGIN_CALLER = 2;
uint256 constant BORROWER = 3;
uint256 constant MARGIN_TRADER = 4;
uint256 constant FEE_SOURCE = 5;
uint256 constant LIQUIDATOR = 6;
uint256 constant AUTHORIZED_FUND_TRADER = 7;
uint256 constant INCENTIVE_REPORTER = 8;
uint256 constant TOKEN_ACTIVATOR = 9;
uint256 constant STAKE_PENALIZER = 10;
uint256 constant LENDER = 11;

uint256 constant FUND = 101;
uint256 constant LENDING = 102;
uint256 constant MARGIN_ROUTER = 103;
uint256 constant CROSS_MARGIN_TRADING = 104;
uint256 constant FEE_CONTROLLER = 105;
uint256 constant PRICE_CONTROLLER = 106;
uint256 constant ADMIN = 107;
uint256 constant INCENTIVE_DISTRIBUTION = 108;
uint256 constant TOKEN_ADMIN = 109;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet (0xEED9D1c6B4cdEcB3af070D85bfd394E7aF179CBd) during
/// beta and will then be transfered to governance
/// https://github.com/marginswap/governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][TOKEN_ACTIVATOR] = true;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                mainCharacters[DEPENDENCY_CONTROLLER] == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = true;
    }

    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = false;
    }

    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        mainCharacters[role] = actor;
    }

    function getRole(uint256 role, address contr) external view returns (bool) {
        return roles[contr][role];
    }

    /// @dev current executor
    function executor() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_CONTROLLER];
        if (depController != address(0)) {
            exec = IDependencyController(depController).currentExecutor();
        }
    }
}