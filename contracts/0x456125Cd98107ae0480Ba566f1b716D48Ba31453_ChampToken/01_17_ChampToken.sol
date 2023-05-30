// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (ChampToken.sol)
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC777/presets/ERC777PresetFixedSupply.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ChampToken
 * @dev Implementation of IERC777. CHAMP token has a limited supply and all CHAMP tokens are mint day 0.
 * An initial array of holders and their associated balance is provided to instantly setup CHAMP initial holders.
 * @custom:security-contact [email protected]
 */
contract ChampToken is
    ERC777PresetFixedSupply,
    Multicall,
    Pausable,
    AccessControl
{
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10**18;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Distribute all tokens to initial holders.
     */
    constructor(address[] memory holders, uint256[] memory balances)
        ERC777PresetFixedSupply(
            "Ultimate Champions Token",
            "CHAMP",
            new address[](0),
            0,
            msg.sender
        )
    {
        require(
            holders.length == balances.length,
            "ChampToken: holders and balances length mismatch"
        );

        _mint(address(this), TOTAL_SUPPLY, "", "", false);
        for (uint256 i = 0; i < holders.length; i++) {
            _send(address(this), holders[i], balances[i], "", "", false);
        }

        require(
            balanceOf(address(this)) == 0,
            "ChampToken: all tokens must be distributed"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @dev Pause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Before token transfer hook.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}