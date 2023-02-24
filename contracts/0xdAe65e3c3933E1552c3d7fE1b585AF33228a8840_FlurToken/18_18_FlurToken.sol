// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Snapshot } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title FlurTokens
 * @author nneverlander. Twitter @nneverlander
 * @notice The Flur Token ($FLUR).
 */
contract FlurToken is
    ERC20("Flur", "FLUR"),
    ERC20Permit("Flur"),
    ERC20Burnable,
    ERC20Snapshot,
    ERC20Votes
{
    address public admin;

    event AdminChanged(address oldAdmin, address newAdmin);

    /**
    @param _admin The address of the admin who will be sent the minted tokens
    @param supply Initial supply of the token
   */
    constructor(address _admin, uint256 supply) {
        admin = _admin;
        // mint initial supply
        _mint(admin, supply);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    // =============================================== ADMIN FUNCTIONS =========================================================

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "zero address");
        admin = newAdmin;
        emit AdminChanged(admin, newAdmin);
    }

    // =============================================== HOOKS =========================================================

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        ERC20Snapshot._beforeTokenTransfer(from, to, amount);
    }

    // =============================================== REQUIRED OVERRIDES =========================================================
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}