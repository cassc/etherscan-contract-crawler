//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../interfaces/IDelegate.sol";
import "../interfaces/IProperty.sol";

/**
    @dev The contract has the authority of the host to operate property contracts.
        It helps Dtravel channel migrate to a new operator address in a single call,
        using transferOwnership() from Ownable.sol
         - Contract owner is ADMIN that has DEFAULT_ADMIN_ROLE
         - ADMIN can grant/revoke DELEGATE_ROLE
 */

contract Delegate is IDelegate, AccessControlEnumerableUpgradeable {
    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");

    function init(address _delegate) external initializer {
        require(_delegate != address(0), "ZeroAddress");
        __AccessControlEnumerable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DELEGATE_ROLE, _delegate);
    }

    function updateHost(IProperty _property, address _host)
        external
        onlyRole(DELEGATE_ROLE)
    {
        require(address(_property) != address(0), "ZeroAddress");
        _property.updateHost(_host);
    }

    function updatePaymentReceiver(IProperty _property, address _receiver)
        external
        onlyRole(DELEGATE_ROLE)
    {
        require(address(_property) != address(0), "ZeroAddress");
        _property.updatePaymentReceiver(_receiver);
    }

    function cancelByHost(IProperty _property, uint256 _bookingId)
        external
        onlyRole(DELEGATE_ROLE)
    {
        require(address(_property) != address(0), "ZeroAddress");
        _property.cancelByHost(_bookingId);
    }
}