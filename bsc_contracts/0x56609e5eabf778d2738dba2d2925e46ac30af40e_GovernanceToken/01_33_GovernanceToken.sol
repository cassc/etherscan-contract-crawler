//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {
    ERC20,
    ERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./internal/Base.sol";
import "./internal/FundForwarder.sol";

contract GovernanceToken is
    FundForwarder,
    ERC20Pausable,
    ERC20Burnable,
    ERC20Permit,
    AccessControlEnumerable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        ITreasury treasury_
    )
        payable
        ERC20Permit(name_)
        ERC20(name_, symbol_)
        FundForwarder(treasury_)
    {
        address sender = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);

        _grantRole(MINTER_ROLE, sender);
        _grantRole(PAUSER_ROLE, sender);
        _grantRole(OPERATOR_ROLE, sender);

        _mint(sender, 69_400_000 * 10**decimals());
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to_, uint256 amount_) external onlyRole(MINTER_ROLE) {
        _mint(to_, amount_ * 10**decimals());
    }

    function updateTreasury(ITreasury treasury_) external override {
        require(address(treasury_) != address(0), "ERC20: ZERO_ADDRESS");
        emit TreasuryUpdated(treasury(), treasury_);
        _updateTreasury(treasury_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }
}