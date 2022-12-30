// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title TokenVault
 * @dev A smart contract to lock an ERC20 token in behalf of user trough an intermediary admin contract.
 * User -> Admin Contract -> Token Vault Contract -> Admin Contract -> User.
 * Tokens can be deposited and withdrawal only with authorization of the locker account from the admin address.
 */
contract TokenVault {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public token;
    address public admin;
    mapping(address => uint256) public balances;

    /// @dev Initializer
    /// @param _token The address of the token to be used
    /// @param _admin The address of the contract that will execute deposits and withdrawals
    constructor(address _token, address _admin) {
        token = IERC20Upgradeable(_token);
        admin = _admin;
    }

    /// @dev Deposit the tokens from the user to the vault from the admin contract
    function deposit(address user, uint256 amount) external {
        require(msg.sender == admin, "TokenVault: Deposit must be sent through admin");
        token.safeTransferFrom(user, address(this), amount);
        balances[user] = balances[user].add(amount);
    }

    /// @dev Withdraw the tokens to the user from the vault from the admin contract
    function withdraw(address user, uint256 amount) external {
        require(msg.sender == admin);
        token.safeTransfer(user, amount);
        balances[user] = balances[user].sub(amount);
    }

    function getToken() external view returns (address) {
        return address(token);
    }

    function getAdmin() external view returns (address) {
        return admin;
    }
}