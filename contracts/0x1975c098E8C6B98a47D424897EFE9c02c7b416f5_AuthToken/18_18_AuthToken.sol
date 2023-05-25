// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../interfaces/IAuthToken.sol";

contract AuthToken is IAuthToken, Ownable, AccessControl, ERC20Permit {
    bytes32 public constant AT_OPERATOR = keccak256("AT_OPERATOR_ROLE");

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address newOperator,
        uint256 amount
    ) ERC20(tokenName, tokenSymbol) ERC20Permit(tokenName) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AT_OPERATOR, newOperator);
        if (amount > 0) {
            _mint(newOperator, amount);
        }
    }

    function grantAdminRole(address admin) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function batchGrantOperator(address[] memory operators) external {
        _checkRole(getRoleAdmin(AT_OPERATOR));
        for (uint256 i = 0; i < operators.length; i++) {
            _grantRole(AT_OPERATOR, operators[i]);
        }
    }

    /**
     * @dev override _transfer
     * Validates that caller is operator
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _checkRole(AT_OPERATOR);
        super._transfer(from, to, amount);
    }

    /**
     * @dev Allow batch transfers
     * @param accounts The addresses that will receive the tokens.
     * @param amounts The amounts of tokens to transfer.
     */
    function batchTransfer(
        address[] memory accounts,
        uint256[] memory amounts
    ) external onlyRole(AT_OPERATOR) {
        address from = _msgSender();
        require(
            (accounts.length <= 100) && (accounts.length == amounts.length)
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            super._transfer(from, accounts[i], amounts[i]);
        }
    }

    /**
     * @dev Function to mint tokens
     * Validates that caller is owner
     * @param account The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Allows the operator to burn some of the other’s tokens
     * @param account The address that will burn the tokens.
     * @param amount uint256 the amount of tokens to be burned
     */
    function burn(
        address account,
        uint256 amount
    ) external onlyRole(AT_OPERATOR) {
        _burn(account, amount);
    }

    /**
     * @dev Allow batch burn
     * @param accounts The addresses that will burn the tokens.
     * @param amounts The amounts of tokens to be burned.
     */
    function batchBurn(
        address[] memory accounts,
        uint256[] memory amounts
    ) external onlyRole(AT_OPERATOR) {
        require(
            (accounts.length <= 100) && (accounts.length == amounts.length)
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            _burn(accounts[i], amounts[i]);
        }
    }
}