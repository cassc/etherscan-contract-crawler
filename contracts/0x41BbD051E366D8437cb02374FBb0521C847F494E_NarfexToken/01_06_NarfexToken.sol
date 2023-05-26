//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NarfexToken v3
/// @author Danil Sakhinov
contract NarfexToken is ERC20, Ownable {

    event Migrate(address indexed account, uint256 amount);
    event MasterChefSet(address newAddress);
    event BurnPercentageSet(uint256 percents);
    event MigrationStop();
    event MigrationRun();

    uint256 constant PERCENT_PRECISION = 10**4; // 10000 = 100%
    uint256 constant AUTOBURN_LIMIT = 10**7 wei; // TotalSupply limit above which burning works
    uint256 private _burnPercentage = 30; // 0.3% of burn/farming fee
    address immutable public v1Token; // Old NRFX address for migration v1
    address immutable public v2Token; // Old NRFX address for migration v2
    address public masterChef; // Farming contract address
    bool public isMigrationEnabled = true; // Is allowed to migrate

    /// @param v1Token_ Olf NRFX address
    /// @param v2Token_ Olf NRFX address
    /// @param masterChef_ Farming contract address
    constructor(address v1Token_, address v2Token_, address masterChef_) ERC20('Narfex', 'NRFX') {
        v1Token = v1Token_;
        v2Token = v2Token_;
        masterChef = masterChef_;

        emit MasterChefSet(masterChef_);
        emit MigrationRun();
    }

    /// @notice Migration from an old token to a new one
    /// @param isV2 True if selected old token version is 2
    /// @dev Withdraw all account funds from the old token and mint on the new one
    function migrate(bool isV2) public {
        require(isMigrationEnabled, "Migration is not enabled");

        // Select old token version
        address token = isV2 ? v2Token : v1Token;
        require(token != address(0), "Old token address not set");

        // Check token balance
        uint256 balance = IERC20(token).balanceOf(msg.sender);
        require(balance > 0, "Insufficient balance");

        // Swap tokens
        IERC20(token).transferFrom(msg.sender, address(this), balance);
        _mint(msg.sender, balance);
        
        emit Migrate(msg.sender, balance);
    }

    /// @notice Shortcut function for compability
    function migrate() public {
        migrate(false);
    }

    /// @notice Transfer with burning or sending to a farming contract
    /// @param spender From account address
    /// @param receiver To account address
    /// @param amount Token amount to send
    function _transferWithFee(address spender, address receiver, uint256 amount) internal {
        require(balanceOf(spender) >= amount, "Insufficient balance");

        // Subtract fee and transfer
        uint256 fee = amount * _burnPercentage / PERCENT_PRECISION;
        uint256 transferAmount = amount - fee;
        _transfer(spender, receiver, transferAmount);

        if (fee == 0) return;
        // Burn fee or transfer fee to a farming contract
        if (totalSupply() >= AUTOBURN_LIMIT) {
            _burn(spender, fee);
        } else {
            _transfer(spender, masterChef, fee);
        }
    }

    /// @notice Transfer from message sender account
    /// @param to Recipient account address
    /// @param amount Amount to transfer
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transferWithFee(_msgSender(), to, amount);
        return true;
    }

    /// @notice Transfer from account
    /// @param from Sender account address
    /// @param to Recipient account address
    /// @param amount Amount to transfer
    /// @return Is operation success
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferWithFee(from, to, amount);
        return true;
    }

    /// @notice Set farming contract address
    /// @param masterChef_ Farming contract address
    function setMasterChef(address masterChef_) public onlyOwner {
        masterChef = masterChef_;
        emit MasterChefSet(masterChef_);
    }

    /// @notice Set fee percent
    /// @param percents Fee percent with 4 digits of precision
    function setBurnPercentage(uint256 percents) public onlyOwner {
        require(percents < 10000, "Fee can't be higher than 100%");
        _burnPercentage = percents;
        emit BurnPercentageSet(percents);
    }

    /// @notice Allow to migrate tokens
    function runMigration() public onlyOwner {
        require(!isMigrationEnabled, "Migration already runned");
        isMigrationEnabled = true;
        emit MigrationRun();
    }

    /// @notice Prevent account from migration
    function stopMigration() public onlyOwner {
        require(isMigrationEnabled, "Migration already stopped");
        isMigrationEnabled = false;
        emit MigrationStop();
    }
}