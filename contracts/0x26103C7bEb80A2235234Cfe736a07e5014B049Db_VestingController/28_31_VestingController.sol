// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IRoles, RolesAuth} from "../../bases/RolesAuth.sol";

import {AccountController, Captable} from "./AccountController.sol";
import {EquityToken} from "../EquityToken.sol";

contract VestingController is AccountController, RolesAuth {
    string public constant moduleId = "org.firm.captable.vesting";
    uint256 public constant moduleVersion = 1;

    struct VestingParams {
        uint40 startDate;
        uint40 cliffDate;
        uint40 endDate;
        address revoker;
    }

    struct Account {
        uint256 amount;
        VestingParams params;
    }

    // owner -> classId -> Account
    mapping(address => mapping(uint256 => Account)) public accounts;

    event VestingCreated(address indexed owner, uint256 indexed classId, uint256 amount, VestingParams params);
    event VestingRevoked(address indexed owner, uint256 indexed classId, uint256 unvestedAmount, uint40 effectiveDate);

    error InvalidVestingParameters();
    error UnauthorizedRevoker();
    error InvalidVestingState();
    error EffectiveDateInThePast();

    function initialize(Captable captable_, IRoles _roles, address trustedForwarder_) public {
        initialize(captable_, trustedForwarder_);
        _setRoles(_roles);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ACCOUNT CONTROLLER INTERFACE
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Function called by Captable to add a new account with vesting
     * @param owner Address of the account owner
     * @param classId Class ID of the account
     * @param amount Amount of tokens being vested
     * @param extraParams Vesting parameters
     */
    function addAccount(address owner, uint256 classId, uint256 amount, bytes calldata extraParams)
        external
        override
        onlyCaptable
    {
        VestingParams memory params = abi.decode(extraParams, (VestingParams));

        if (params.startDate > params.cliffDate || params.cliffDate > params.endDate) {
            revert InvalidVestingParameters();
        }

        _validateAuthorizedAddress(params.revoker);

        Account storage account = accounts[owner][classId];
        if (account.amount > 0) {
            revert AccountAlreadyExists();
        }

        account.amount = amount;
        account.params = params;

        emit VestingCreated(owner, classId, amount, params);
    }

    /**
     * @notice Function called by Captable to check whether a transfer is allowed depending on vesting state
     * @param from Address of the account owner
     * @param classId Class ID of the account
     * @param amount Amount of tokens being transferred
     */
    function isTransferAllowed(address from, address, uint256 classId, uint256 amount) external view returns (bool) {
        Account storage account = accounts[from][classId];

        if (account.amount == 0) {
            revert AccountDoesntExist();
        }

        uint256 lockedAmount = calculateLockedAmount(account.amount, account.params, block.timestamp);

        if (lockedAmount > 0) {
            uint256 beforeBalance = captable().balanceOf(from, classId);
            if (beforeBalance < lockedAmount) {
                return false;
            }
            uint256 afterBalance = beforeBalance - amount;
            return afterBalance >= lockedAmount;
        }

        return true;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // VESTING MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    function revokeVesting(address owner, uint256 classId) external {
        revokeVesting(owner, classId, uint40(block.timestamp));
    }

    /**
     * @notice Revoke vesting for an account, transferring unvested tokens to Safe
     * @param owner Address of the account owner
     * @param classId Class ID of the account
     * @param effectiveDate Date from which the vesting is revoked
     */
    function revokeVesting(address owner, uint256 classId, uint40 effectiveDate) public {
        Account storage account = accounts[owner][classId];

        if (account.amount == 0) {
            revert AccountDoesntExist();
        }

        if (effectiveDate < block.timestamp) {
            revert EffectiveDateInThePast();
        }

        if (!_isAuthorized(_msgSender(), account.params.revoker)) {
            revert UnauthorizedRevoker();
        }

        uint256 unvestedAmount = calculateLockedAmount(account.amount, account.params, effectiveDate);
        if (unvestedAmount == 0) {
            revert InvalidVestingState();
        }

        uint256 ownerBalance = captable().balanceOf(owner, classId);
        uint256 forcedTransferAmount = ownerBalance > unvestedAmount ? unvestedAmount : ownerBalance;

        emit VestingRevoked(owner, classId, unvestedAmount, effectiveDate);

        captable().controllerForcedTransfer(owner, address(safe()), classId, forcedTransferAmount, "Vesting revoked");
        _cleanup(owner, classId);
    }

    /**
     * @notice Cleanup vesting account after it has been fully vested
     * @dev Can be called by anyone, will result in gas savings for owner as controller will not be
     *      called from now on
     * @param owner Address of the account owner
     * @param classId Class ID of the account
     */
    function cleanupFullyVestedAccount(address owner, uint256 classId) external {
        Account storage account = accounts[owner][classId];

        if (account.amount == 0) {
            revert AccountDoesntExist();
        }

        uint256 lockedAmount = calculateLockedAmount(account.amount, account.params, block.timestamp);
        if (lockedAmount > 0) {
            revert InvalidVestingState();
        }

        _cleanup(owner, classId);
    }

    function _cleanup(address owner, uint256 classId) internal {
        captable().controllerDettach(owner, classId);
        delete accounts[owner][classId];
    }

    function calculateLockedAmount(uint256 amount, VestingParams memory params, uint256 time)
        internal
        pure
        returns (uint256)
    {
        if (time >= params.endDate) {
            return 0;
        }

        if (time < params.cliffDate) {
            return amount;
        }

        return amount * (params.endDate - time) / (params.endDate - params.startDate);
    }
}