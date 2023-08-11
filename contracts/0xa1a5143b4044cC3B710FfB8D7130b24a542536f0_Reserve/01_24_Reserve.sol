// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./interfaces/IController.sol";
import "../lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract Reserve is Owned(msg.sender) {
    using FixedPointMathLib for uint256; 
    using SafeTransferLib for ERC20;

    address public factory;
    ERC20 constant CRVUSD = ERC20(address(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E));
    mapping (address => uint256) public balances;
    mapping (address => bool) public vaults;
    uint256 public feesCollected = 0;

    event Deposited(address user, uint256 amount, uint256 totalBalance);
    event DepositedFor(address from, address user, uint256 amount, uint256 totalBalance);
    event Withdrew(address user, uint256 amount, uint256 totalBalance);
    event WithdrawFormVault(address vault, address user, uint256 debtFees, uint256 debtTreasuryFees, uint256 totalBalance);
    event VaultAdded(address vault);
    event SetFactory(address factory);
    event FeesCollected(uint256 fees);

    function deposit(uint256 amount) external {
        CRVUSD.safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;

        emit Deposited(msg.sender, amount, balances[msg.sender]);
    }

    function deposit_for(address user, uint256 amount) external {
        CRVUSD.safeTransferFrom(msg.sender, address(this), amount);
        balances[user] += amount;

        emit DepositedFor(msg.sender, user, amount, balances[user]);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough funds");
        balances[msg.sender] -= amount;
        CRVUSD.safeTransfer(msg.sender, amount);

        emit Withdrew(msg.sender, amount, balances[msg.sender]);
    }

    function withdraw_from_vault(address user, uint256 debtFees, uint256 debtTreasuryFees) external {
        require(vaults[msg.sender] == true, "!Auth");

        uint256 amount = debtFees + debtTreasuryFees;
        require(balances[user] >= amount, "Not enough funds");

        balances[user] -= amount;
        CRVUSD.safeTransfer(msg.sender, debtFees);

        feesCollected += debtTreasuryFees;

        emit WithdrawFormVault(msg.sender, user, debtFees, debtTreasuryFees, balances[user]);
    }

    function addVault(address vault) external {
        require(msg.sender == factory, "!Auth");
        vaults[vault] = true;

        emit VaultAdded(vault);
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
        emit SetFactory(factory);
    }

    function collect_fees() external {
        uint256 tmp = feesCollected;
        feesCollected = 0;
        CRVUSD.safeTransfer(owner, tmp);
        emit FeesCollected(tmp);
    }
}