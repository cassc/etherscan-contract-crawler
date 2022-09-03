// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//Governor agent, after deployment owner will transfer to multi-signature account
contract AccessControlProxy is Initializable, AccessControlEnumerable {
    /// same privileges as `gov_role`
    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");
    /// configuring options within the vault contract
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    /// can `rebalance` the vault via the strategy contract
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    function initialize(
        address _governance,
        address _delegate,
        address _vault,
        address _keeper
    ) public initializer {
        require(
            !(_governance == address(0) ||
                _delegate == address(0) ||
                _vault == address(0) ||
                _keeper == address(0))
        );

        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(DELEGATE_ROLE, _delegate);
        _grantRole(VAULT_ROLE, _vault);
        _grantRole(KEEPER_ROLE, _keeper);

        // gov is its own admin
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(DELEGATE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(VAULT_ROLE, DELEGATE_ROLE);
        _setRoleAdmin(KEEPER_ROLE, DELEGATE_ROLE);

    }

    function addRole(bytes32 _role, bytes32 _roleAdmin) external {
        require(isGovOrDelegate(msg.sender));
        require(getRoleAdmin(_role) == bytes32(0) && getRoleMemberCount(_role) == 0);
        _setRoleAdmin(_role, _roleAdmin);
    }

    function isGovOrDelegate(address _account) public view returns (bool) {
        return hasRole(DELEGATE_ROLE, _account) || hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function isVaultOrGov(address _account) public view returns (bool) {
        return hasRole(VAULT_ROLE, _account) || isGovOrDelegate(_account);
    }

    function isKeeperOrVaultOrGov(address _account) public view returns (bool) {
        return hasRole(KEEPER_ROLE, _account) || isVaultOrGov(_account);
    }

    function checkRole(bytes32 _role, address _account) external view {
        _checkRole(_role, _account);
    }

    function checkGovOrDelegate(address _account) public view {
        if (!isGovOrDelegate(_account)) {
            revert(encodeErrorMsg(_account, "governance"));
        }
    }

    function checkVaultOrGov(address _account) public view {
        if (!isVaultOrGov(_account)) {
            revert(encodeErrorMsg(_account, "vault manager"));
        }
    }

    function checkKeeperOrVaultOrGov(address _account) public view {
        if (!isKeeperOrVaultOrGov(_account)) {
            revert(encodeErrorMsg(_account, "keeper"));
        }
    }

    function encodeErrorMsg(address _account, string memory _roleName)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(_account), 20),
                    " at least role ",
                    _roleName
                )
            );
    }
}