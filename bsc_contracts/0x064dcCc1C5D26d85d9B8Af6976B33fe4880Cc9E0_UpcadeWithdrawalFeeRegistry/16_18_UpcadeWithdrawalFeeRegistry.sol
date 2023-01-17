//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/Withdrawable.sol";
import "./utils/AccessControlled.sol";

contract UpcadeWithdrawalFeeRegistry is Ownable, Withdrawable, AccessControlled {
    address public vault;

    event Deposited(address indexed from, string uuid, uint256 amount);

    modifier protectedWithdrawal() override {
        _checkRole(MANAGER_ROLE);
        _;
    }

    constructor() {
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /* Configuration
     ****************************************************************/

    function setVault(address vault_) external onlyRole(MANAGER_ROLE) {
        require(vault_ != address(0), "Cannot set to the zero address");

        vault = vault_;
    }

    /* Domain
     ****************************************************************/

    function pay(string calldata uuid) external payable {
        require(msg.value > 0, "Amount must be greater than zero");

        (bool sent, ) = payable(vault).call{ value: msg.value }("");

        require(sent, "Failed to transfer the fee");

        emit Deposited(_msgSender(), uuid, msg.value);
    }
}