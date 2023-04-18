// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

interface IAllowlist {
    function allowed(address _address) external view returns (bool);
}

contract Allowlist is
    Initializable,
    AccessControlEnumerableUpgradeable,
    IAllowlist
{
    // Roles
    bytes32 public constant ALLOWLISTER = keccak256("ALLOWLISTER");
    bytes32 public constant BLOCKLISTER = keccak256("BLOCKLISTER");

    mapping(address => bool) public _allowed;

    event Allowlisted(address indexed _address);
    event Blocklisted(address indexed _address);

    // Initializer
    function initialize() public initializer {
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(ALLOWLISTER, msg.sender);
        _setupRole(BLOCKLISTER, msg.sender);
    }

    function allowed(address _address) external view returns (bool) {
        return _allowed[_address];
    }

    /**
     * @dev Add addressess to allowlist
     * @param addresses Array of addresses to add to whitelist
     */
    function allowlist(
        address[] calldata addresses
    ) external onlyRole(ALLOWLISTER) {
        for (uint256 i = 0; i < addresses.length; i++) {
            // Skip if already allowlisted
            if (_allowed[addresses[i]]) continue;

            _allowed[addresses[i]] = true;
            emit Allowlisted(addresses[i]);
        }
    }

    /**
     * @dev Remove addressess from allowlist
     * @param addresses Array of addresses to remove from allowlist
     */
    function blocklist(
        address[] calldata addresses
    ) external onlyRole(BLOCKLISTER) {
        for (uint256 i = 0; i < addresses.length; i++) {
            // Skip if already blacklisted
            if (!_allowed[addresses[i]]) continue;

            _allowed[addresses[i]] = false;
            emit Blocklisted(addresses[i]);
        }
    }
}