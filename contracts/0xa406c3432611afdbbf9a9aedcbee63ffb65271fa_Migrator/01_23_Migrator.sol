// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UpgradeableBase } from "./UpgradeableBase.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMigrator {
    struct Vault {
        uint256 amount;
        uint256 depositTs;
        bool active;
    }

    event ConfigChanged(uint256 minDeposit);

    function deposit(uint256 amount) external;
    function claim(uint256 id) external;
}

contract Migrator is UpgradeableBase, IMigrator {
    IERC20 public srcToken;
    IERC20 public destToken;
    uint256 public exchangeRatio;
    uint256 public maturity;
    uint256 public bonusPeriod;
    uint256 public minDeposit;
    mapping(address user => mapping(uint256 id => Vault)) public vaults;
    mapping(address user => uint256 id) public nextVaultId;
    uint256 constant WAD = 1e18;

    using SafeERC20 for IERC20;

    constructor() {
        _disableInitializers();
    }

    /// @dev Use portfolio.paused() for pausable
    /// @param _exchangeRatio decimal 18
    /// @param _maturity seconds
    /// @param _bonusPeriod seconds
    /// @param _minDeposit decimal of source token
    function initialize(
        IERC20 _src,
        IERC20 _dest,
        uint256 _exchangeRatio,
        uint256 _maturity,
        uint256 _bonusPeriod,
        uint256 _minDeposit,
        address manager
    )
        public
        initializer
    {
        __UpgradeableBase_init(manager);
        _grantManagerRole(manager);

        srcToken = _src;
        destToken = _dest;
        exchangeRatio = _exchangeRatio;
        maturity = _maturity;
        bonusPeriod = _bonusPeriod;
        minDeposit = _minDeposit;
    }

    function deposit(uint256 amount) public whenNotPaused {
        require(amount >= minDeposit, "Less than minDeposit");

        address sender = _msgSender();
        uint256 vaultId = nextVaultId[sender];

        srcToken.safeTransferFrom(sender, address(this), amount);

        vaults[sender][vaultId] = Vault({ amount: amount, depositTs: block.timestamp, active: true });
        nextVaultId[sender] += 1;
    }

    // TODO: check zero in, one out
    // @dev Set vault.active false, not delete the vault
    function claim(uint256 id) public whenNotPaused {
        address sender = _msgSender();

        require(id < nextVaultId[sender], "Vault Not Found");
        Vault memory vault = vaults[sender][id];

        require(vault.active, "Vault Already Claimed");

        uint256 srcTokenAmount = 0;
        uint256 destTokenAmount = 0;
        uint256 depositTs = vault.depositTs;
        uint256 duration = block.timestamp - depositTs;

        // calculate (srcAmount, destAmount) to transfer
        if (block.timestamp <= depositTs + maturity) {
            // case1. Before Maturity(143 weeks)
            uint256 srcTokenAmountToExchange = vault.amount * duration / maturity;
            destTokenAmount = srcTokenAmountToExchange * exchangeRatio / WAD;
            srcTokenAmount = vault.amount - srcTokenAmountToExchange;
        } else if (block.timestamp <= depositTs + maturity + bonusPeriod) {
            // case2. In Bonus period (37 weeks)
            uint256 passedBonusPeriod = block.timestamp - depositTs - maturity;
            uint256 srcTokenAmountToExchange = vault.amount * (maturity + passedBonusPeriod) / maturity;
            destTokenAmount = srcTokenAmountToExchange * exchangeRatio / WAD;
            // srcTokenAmount is 0
        } else {
            // case3. After Bonus period (37 weeks)
            uint256 srcTokenAmountToExchange = vault.amount * (maturity + bonusPeriod) / maturity;
            destTokenAmount = srcTokenAmountToExchange * exchangeRatio / WAD;
            // srcTokenAmount is 0
        }

        // Update storage
        vaults[sender][id].active = false;

        if (srcTokenAmount != 0) {
            srcToken.safeTransfer(sender, srcTokenAmount);
        }
        if (destTokenAmount != 0) {
            destToken.safeTransfer(sender, destTokenAmount);
        }
    }

    function setConfig(uint256 _minDeposit) external onlyManager {
        minDeposit = _minDeposit;
        emit ConfigChanged(_minDeposit);
    }
}