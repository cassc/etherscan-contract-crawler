pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IWhitelist.sol";

contract Whitelist is IWhitelist, AccessControl {
    // accessControl Roles
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    // this address is used in the _whitelistClients mapping to represent all vaults
    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MOD_ROLE, _msgSender());
    }

    mapping(address => mapping(address => bool)) private _whitelistedClients;

    event AddedToWhitelist(address indexed client, address indexed vault);
    event RemovedFromWhitelist(address indexed client, address indexed vault);

    // add an address to the whitelist
    function addToWhitelist(address clientAddress, address vault) external onlyRole(MOD_ROLE) {
        require(vault != ZERO_ADDRESS, "You can only add whitelist for one vault with this function");
        _addToWhitelist(clientAddress, vault);
    }

    // add an address to the whitelist for all vaults
    function addToWhitelistAllVaults(address clientAddress) external onlyRole(MOD_ROLE) {
        _addToWhitelist(clientAddress, ZERO_ADDRESS);
    }

    function _addToWhitelist(address clientAddress, address vault) internal virtual {
        require(
            !_whitelistedClients[clientAddress][vault] && !_whitelistedClients[clientAddress][ZERO_ADDRESS],
            "This address is already whitelisted"
        );
        _whitelistedClients[clientAddress][vault] = true;
        emit AddedToWhitelist(clientAddress, vault);
    }

    // remove an address from the whitelist
    function removeFromWhitelist(address clientAddress, address vault) external onlyRole(MOD_ROLE) {
        require(vault != ZERO_ADDRESS, "You can only remove whitelist for one vault with this function");
        _removeFromWhitelist(clientAddress, vault);
    }

    // remove an address from the whitelist for all vaults
    function removeFromWhitelistAllVaults(address clientAddress) external onlyRole(MOD_ROLE) {
        _removeFromWhitelist(clientAddress, ZERO_ADDRESS);
    }

    function _removeFromWhitelist(address clientAddress, address vault) internal virtual {
        require(_whitelistedClients[clientAddress][vault], "This address is not whitelisted");
        delete _whitelistedClients[clientAddress][vault];
        emit RemovedFromWhitelist(clientAddress, vault);
    }

    // vault check for whitelist status
    function isWhitelisted(address clientAddress) external view override returns (bool) {
        return _whitelistedClients[clientAddress][ZERO_ADDRESS] || _whitelistedClients[clientAddress][msg.sender];
    }

    // mod check for whitelist status
    function isWhitelistedMod(address clientAddress, address vault) external view returns (bool) {
        return _whitelistedClients[clientAddress][vault];
    }
}