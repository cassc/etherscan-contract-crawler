// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *   __                                    __          __
 *  |  | ___\|/_    ____   ____ _\|/_    _/  |_  ____ |  | __ ____   ____
 *  |  |/ /\__  \  /    \ /    \\__  \   \   __\/  _ \|  |/ // __ \ /    \
 *  |    <  / __ \|   |  \   |  \/ __ \_  |  | ( _\|/_)    <\  ___/|   |  \
 *  |__|_ \(____  /___|  /___|  (____  /  |__|  \____/|__|_ \\___  >___|  /
 *       \/     \/     \/     \/     \/                    \/    \/     \/
 *
 *  @title KNN Token (ERC20)
 *  @author KANNA Team
 *  @custom:github  https://github.com/kanna-coin
 *  @custom:site https://kannacoin.io
 *  @custom:discord https://discord.gg/V5KDU8DKCh
 */
contract KannaToken is ERC20, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant INITIAL_SUPPLY = 10_000_000 * 10**18;
    uint256 public constant MAX_SUPPLY = 19_000_000 * 10**18;

    address public treasury;

    event TreasuryUpdate(address indexed sender, address indexed fromTreasury, address newTreasury);

    constructor() ERC20("KNN Token", "KNN") {}

    /** @dev Creates {INITIAL_SUPPLY} and assigns them to {treasury} account
     *
     * Emits a {TreasuryUpdate} event with `sender` set to the sender address
     *
     * Requirements:
     *
     * - the caller must have admin role
     */
    function initializeTreasury(address newTreasury) external onlyOwner {
        require(treasury == address(0), "Treasury already initialized");
        _updateTreasury(newTreasury);
        _mint(treasury, INITIAL_SUPPLY);
    }

    /** @dev Creates `amount` tokens and assigns them to {treasury} account, increasing
     * the total supply which is limited to {MAX_SUPPLY}.
     *
     * Emits a {TreasuryUpdate} event with `sender` set to the sender address
     *
     * Requirements:
     *
     * - the caller must have admin role
     */
    function updateTreasury(address newTreasury) external onlyOwner {
        _updateTreasury(newTreasury);
    }

    /** @dev Creates `amount` tokens and assigns them to {treasury} account, increasing
     * the total supply which is limited to {MAX_SUPPLY}.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - the caller must have a minter role.
     */
    function mint(uint256 amount) external onlyRole(MINTER_ROLE) {
        require(amount > 0, "Invalid Amount");
        require(totalSupply() + amount <= MAX_SUPPLY, "Maximum Supply reached!");
        _mint(treasury, amount);
    }

    /**
     * @dev Grants `MINTER_ROLE` to a `minter` account.
     *
     * If `minter` account had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function addMinter(address newMinter) external onlyOwner {
        _grantRole(MINTER_ROLE, newMinter);
    }

    /**
     * @dev Removes `MINTER_ROLE` from a `minter` account.
     *
     * If `minter` had been granted `MINTER_ROLE`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function removeMinter(address minter) external onlyOwner {
        _revokeRole(MINTER_ROLE, minter);
    }

    function _updateTreasury(address newTreasury) internal virtual {
        require(newTreasury != address(0), "Invalid treasury address");
        emit TreasuryUpdate(msg.sender, treasury, newTreasury);
        treasury = newTreasury;
    }
}