// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract Controllable is AccessControlEnumerableUpgradeable {

    mapping(address => uint8) internal _accountStatus;

    event GovernanceUpdated(address indexed account);

    /**
     * @dev Restricted to members of the Governance role.
     */
    modifier onlyGovernance() {
        require(
            isGovernance(_msgSender()),
            "Controllable: Restricted to Governance"
        );
        _;
    }

    /**
     * @dev Initialize the contract and set the Governance role.
     */
    function __Controllable_init(address Governance)
        internal
        onlyInitializing
    {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, Governance);
    }

    /**
     * @dev Return `true` if the account belongs to the gouvernanc role.
     */
    function isGovernance(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev Change the Governance role.
     * This will remove the Governance role from the first address holding this role and give it to the selected address.
     */
    function updateGovernance(address account)
        external
        virtual
        onlyGovernance
        returns (bool)
    {
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, account);

        emit GovernanceUpdated(account);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}