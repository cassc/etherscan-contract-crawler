// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/access/AccessControl.sol';

contract AccessMinter is Ownable, AccessControl {
    using Address for address;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    address internal currentMinter;
    bool internal canRevoke = false;

    modifier revokable {
        canRevoke = true;
        _;
        canRevoke = false;
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender),
            'AccessMinter: only minter can call this method');
        _;
    }

    modifier onlyMinterOrOwner {
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender),
            'AccessMinter: only minter or owner can call this method');
        _;
    }

    constructor() {
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setupRole(MINTER_ROLE, owner());
        currentMinter = owner();
    }

    function grantRole(bytes32 role, address account) public virtual override revokable {
        AccessControl.grantRole(role, account);

        if(role == MINTER_ROLE) {
            AccessControl.revokeRole(role, currentMinter);
            currentMinter = account;
        }
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        require(canRevoke, "AccessMinter: revoke not allowed!");
        AccessControl.revokeRole(role, account);
    }

    function changeMinter(address account) external returns (bool) {
        grantRole(MINTER_ROLE, account);
        return true;
    }

    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }
}