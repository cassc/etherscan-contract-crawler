// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IChangeMakers.sol";

/**
 * @title ChangeMakers
 * @author ChangeDao
 * @dev Stores addresses of approved changeMakers.  ChangeDao designates managers that approve/revoke changemaker addresses.
 */

contract ChangeMakers is IChangeMakers, AccessControl {
    /* ============== State Variables ============== */

    bytes32 constant private _CHANGEMAKERS_MANAGER =
        keccak256("CHANGEMAKERS_MANAGER");
    mapping(address => bool) public override approvedChangeMakers;

    /* ============== Constructor ============== */

    /**
     * @notice A CHANGEMAKERS_MANAGER is an address that can approve/revoke a changemaker address, thus granting/revoking access to use the platform
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(_CHANGEMAKERS_MANAGER, _msgSender());
    }

    /* ============== Setter Functions ============== */

    /**
     * @notice An address with the CHANGEMAKERS_MANAGER role grants access to a changeMaker to use factory functions on the Controller contract.
     * @param _changeMaker Address of approved changeMaker
     */
    function approveChangeMaker(address _changeMaker)
        external
        override
        onlyRole(_CHANGEMAKERS_MANAGER)
    {
        require(_changeMaker != address(0x0), "CM: Changemaker is zero address");
        approvedChangeMakers[_changeMaker] = true;
        emit ChangeMakerApproved(_changeMaker);
    }

    /**
     * @notice An address with the CHANGEMAKERS_MANAGER role revokes changeMaker status
     * @param _changeMaker Address of revoked changeMaker
     */
    function revokeChangeMaker(address _changeMaker)
        external
        override
        onlyRole(_CHANGEMAKERS_MANAGER)
    {
        approvedChangeMakers[_changeMaker] = false;
        emit ChangeMakerRevoked(_changeMaker);
    }
}