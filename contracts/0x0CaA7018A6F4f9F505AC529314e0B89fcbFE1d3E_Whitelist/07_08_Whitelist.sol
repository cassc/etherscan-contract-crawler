// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IWhitelist.sol";

contract Whitelist is IWhitelist, ERC165, AccessControl {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    mapping(address => bool) public whitelist;

    constructor(address _owner) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MODERATOR_ROLE, _owner);
    }

    function addToWhitelist(address _address)
        external
        onlyRole(MODERATOR_ROLE)
    {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address)
        external
        onlyRole(MODERATOR_ROLE)
    {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IWhitelist).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}