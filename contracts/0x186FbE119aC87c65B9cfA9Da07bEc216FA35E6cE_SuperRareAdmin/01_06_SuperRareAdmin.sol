// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SuperRareAdmin is Ownable, AccessControl {
    bytes32 public constant SUPER_RARE_WHITELIST_ROLE =
        keccak256("SUPER_RARE_WHITELIST_ROLE");

    address public superRareV2Contract;

    constructor(address _superRareV2Contract) {
        superRareV2Contract = _superRareV2Contract;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addToWhitelist(address _newAddress) external {
        require(
            hasRole(SUPER_RARE_WHITELIST_ROLE, msg.sender),
            "doesnt have whitelist role"
        );
        (bool success, bytes memory data) = superRareV2Contract.call(
            abi.encodeWithSignature("addToWhitelist(address)", _newAddress)
        );

        require(success, string(data));
        return;
    }

    function removeFromWhitelist(address _removedAddress) external {
        require(
            hasRole(SUPER_RARE_WHITELIST_ROLE, msg.sender),
            "doesnt have whitelist role"
        );
        (bool success, bytes memory data) = superRareV2Contract.call(
            abi.encodeWithSignature(
                "removeFromWhitelist(address)",
                _removedAddress
            )
        );

        require(success, string(data));
        return;
    }

    function transferOwnershipOfSuperRareV2(address _newOwner)
        external
        onlyOwner
    {
        (bool success, bytes memory data) = superRareV2Contract.call(
            abi.encodeWithSignature("transferOwnership(address)", _newOwner)
        );

        require(success, string(data));
        return;
    }
}