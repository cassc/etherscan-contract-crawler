// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./interfaces/IComplianceManager.sol";
import "./interfaces/IFluentUSPlus.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract ComplianceManager is
    IComplianceManager,
    Initializable,
    AccessControlUpgradeable
{
    int public constant Version = 3;
    event AddedToAllowList(address indexed user, string message);
    event RemovedFromAllowList(address indexed user, string message);
    event AddedToBlockList(address indexed user, string message);
    event RemovedFromBlockList(address indexed user, string message);

    /**
     * FFC_INPUT_ROLE for the actor who is allowed to add and remove addresses from the Allowlist.
     * FEDMEMBER_INPUT_ROLE for the actor who is allowed to add and remove addresses from the Blocklist.
     * The Allowlist is used in the burn flow as a check to verify if the Fedmember is Allowlisted.
     * The blocklist is used in the mint flow as a check to verify if the address "to" has any restriction.
     * Controlling blocklisted address is a control responsibility of the Federation Members not to the FFC.
     */
    bytes32 public constant FFC_INPUT_ROLE = keccak256("FFC_INPUT_ROLE");
    bytes32 public constant FEDMEMBER_INPUT_ROLE =
        keccak256("FEDMEMBER_INPUT_ROLE");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");

    mapping(address => bool) public blockList;
    mapping(address => bool) public allowList;

    function initialize() public initializer {
        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(FFC_INPUT_ROLE, msg.sender);
    }

    function addBlockList(
        address addr
    ) external onlyRole(FEDMEMBER_INPUT_ROLE) {
        require(!blockList[addr], "Address already in the BlockList");
        if (allowList[addr]) removeFromAllowList(addr);
        blockList[addr] = true;
        emit AddedToBlockList(addr, "Successfully added to BlockList");
    }

    function removeFromBlockList(
        address addr
    ) external onlyRole(FEDMEMBER_INPUT_ROLE) {
        require(blockList[addr], "Address not in the BlockList");
        emit RemovedFromBlockList(addr, "Successfully removed from BlockList");
        blockList[addr] = false;
    }

    /**
     * For control proposes if an address needs to be added to the AllowList it could not
     * currently be in the BlockList.
     */
    function addAllowList(address addr) external onlyRole(FFC_INPUT_ROLE) {
        require(!blockList[addr], "Address in the BlockList. Remove it first");
        require(!allowList[addr], "Address already in the AllowList");
        emit AddedToAllowList(addr, "Successfully added to AllowList");
        allowList[addr] = true;
    }

    function removeFromAllowList(address addr) public onlyRole(FFC_INPUT_ROLE) {
        require(allowList[addr], "Address not in the AllowList");
        emit RemovedFromAllowList(addr, "Successfully removed from AllowList");
        allowList[addr] = false;
    }

    function checkWhiteList(address _addr) external view returns (bool) {
        return allowList[_addr];
    }

    function checkBlackList(address _addr) external view returns (bool) {
        return blockList[_addr];
    }

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(erc20Addr),
            to,
            amount
        );
    }
}