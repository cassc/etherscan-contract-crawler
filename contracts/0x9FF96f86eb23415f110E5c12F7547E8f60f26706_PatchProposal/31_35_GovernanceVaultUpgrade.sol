// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { Governance } from "../v1/Governance.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ITornadoVault } from "./interfaces/ITornadoVault.sol";

/// @title Version 2 Governance contract of the tornado.cash governance
contract GovernanceVaultUpgrade is Governance {
    using SafeMath for uint256;

    // vault which stores user TORN
    ITornadoVault public immutable userVault;

    // call Governance v1 constructor
    constructor(address _userVault) public Governance() {
        userVault = ITornadoVault(_userVault);
    }

    /// @notice Withdraws TORN from governance if conditions permit
    /// @param amount the amount of TORN to withdraw
    function unlock(uint256 amount) public virtual override {
        require(getBlockTimestamp() > canWithdrawAfter[msg.sender], "Governance: tokens are locked");
        lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(amount, "Governance: insufficient balance");
        userVault.withdrawTorn(msg.sender, amount);
    }

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual returns (string memory) {
        return "2.vault-migration";
    }

    /// @notice transfers tokens from the contract to the vault, withdrawals are unlock()
    /// @param owner account/contract which (this) spender will send to the user vault
    /// @param amount amount which spender will send to the user vault
    function _transferTokens(address owner, uint256 amount) internal virtual override {
        require(torn.transferFrom(owner, address(userVault), amount), "TORN: transferFrom failed");
        lockedBalance[owner] = lockedBalance[owner].add(amount);
    }
}