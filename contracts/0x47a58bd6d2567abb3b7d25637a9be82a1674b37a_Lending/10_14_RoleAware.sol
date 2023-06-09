// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware {
    Roles public immutable roles;
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Roles(_roles);
    }

    modifier noIntermediary() {
        require(
            msg.sender == tx.origin,
            "Currently no intermediaries allowed for this function call"
        );
        _;
    }

    // @dev Throws if called by any account other than the owner or executor
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || executor() == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                disabler() == msg.sender,
            "Caller is not the owner, executor or authorized disabler"
        );
        _;
    }

    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                isTokenActivator(msg.sender),
            "Caller is not the owner, executor or authorized activator"
        );
        _;
    }

    function updateRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.getRole(role, contr);
    }

    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    function owner() internal view returns (address) {
        return roles.owner();
    }

    function executor() internal returns (address) {
        return roles.executor();
    }

    function disabler() internal view returns (address) {
        return mainCharacterCache[DISABLER];
    }

    function fund() internal view returns (address) {
        return mainCharacterCache[FUND];
    }

    function lending() internal view returns (address) {
        return mainCharacterCache[LENDING];
    }

    function marginRouter() internal view returns (address) {
        return mainCharacterCache[MARGIN_ROUTER];
    }

    function crossMarginTrading() internal view returns (address) {
        return mainCharacterCache[CROSS_MARGIN_TRADING];
    }

    function feeController() internal view returns (address) {
        return mainCharacterCache[FEE_CONTROLLER];
    }

    function price() internal view returns (address) {
        return mainCharacterCache[PRICE_CONTROLLER];
    }

    function admin() internal view returns (address) {
        return mainCharacterCache[ADMIN];
    }

    function incentiveDistributor() internal view returns (address) {
        return mainCharacterCache[INCENTIVE_DISTRIBUTION];
    }

    function tokenAdmin() internal view returns (address) {
        return mainCharacterCache[TOKEN_ADMIN];
    }

    function isBorrower(address contr) internal view returns (bool) {
        return roleCache[contr][BORROWER];
    }

    function isFundTransferer(address contr) internal view returns (bool) {
        return roleCache[contr][FUND_TRANSFERER];
    }

    function isMarginTrader(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_TRADER];
    }

    function isFeeSource(address contr) internal view returns (bool) {
        return roleCache[contr][FEE_SOURCE];
    }

    function isMarginCaller(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_CALLER];
    }

    function isLiquidator(address contr) internal view returns (bool) {
        return roleCache[contr][LIQUIDATOR];
    }

    function isAuthorizedFundTrader(address contr)
        internal
        view
        returns (bool)
    {
        return roleCache[contr][AUTHORIZED_FUND_TRADER];
    }

    function isIncentiveReporter(address contr) internal view returns (bool) {
        return roleCache[contr][INCENTIVE_REPORTER];
    }

    function isTokenActivator(address contr) internal view returns (bool) {
        return roleCache[contr][TOKEN_ACTIVATOR];
    }

    function isStakePenalizer(address contr) internal view returns (bool) {
        return roleCache[contr][STAKE_PENALIZER];
    }

    function isLender(address contr) internal view returns (bool) {
        return roleCache[contr][LENDER];
    }
}