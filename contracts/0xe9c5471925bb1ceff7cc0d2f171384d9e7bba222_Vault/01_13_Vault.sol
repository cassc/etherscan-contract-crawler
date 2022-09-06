// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../utils/NoContractUpgradeable.sol";
import "../../interfaces/IStrategy.sol";

/// @title JPEG'd vault
/// @notice Allows users to deposit fungible assets into autocompounding strategy contracts (e.g. {StrategyPUSDConvex}).
/// Non whitelisted contracts can't deposit/withdraw.
/// Owner is DAO
contract Vault is ERC20PausableUpgradeable, NoContractUpgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;

    event Deposit(address indexed from, address indexed to, uint256 value);
    event Withdrawal(address indexed withdrawer, address indexed to, uint256 wantAmount);
    event StrategyMigrated(
        IStrategy indexed newStrategy,
        IStrategy indexed oldStrategy
    );
    event FeeRecipientChanged(
        address indexed newRecipient,
        address indexed oldRecipient
    );

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    ERC20Upgradeable public token;

    IStrategy public strategy;

    address public feeRecipient;
    Rate public depositFeeRate;

    /// @param _token The token managed by this vault
    /// @param _feeRecipient The fee recipient
    /// @param _depositFeeRate The deposit fee
    function initialize(
        ERC20Upgradeable _token,
        address _feeRecipient,
        Rate memory _depositFeeRate
    ) external initializer {
        __ERC20_init(
            string(abi.encodePacked("JPEG\xE2\x80\x99d ", _token.name())),
            string(abi.encodePacked("JPEGD", _token.symbol()))
        );
        __noContract_init();

        _pause();

        setFeeRecipient(_feeRecipient);
        setDepositFeeRate(_depositFeeRate);
        token = _token;
    }

    /// @inheritdoc ERC20Upgradeable
    function decimals() public view virtual override returns (uint8) {
        return token.decimals();
    }

    /// @return assets The total amount of tokens managed by this vault and the underlying strategy
    function totalAssets() public view returns (uint256 assets) {
        assets = token.balanceOf(address(this));

        IStrategy _strategy = strategy;
        if (address(_strategy) != address(0)) assets += strategy.totalAssets();
    }

    /// @return The underlying tokens per share
    function exchangeRate() external view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        return (totalAssets() * (10**decimals())) / supply;
    }

    /// @notice Allows users to deposit `token`. Contracts can't call this function
    /// @param _to The address to send the tokens to
    /// @param _amount The amount to deposit
    function deposit(address _to, uint256 _amount)
        external
        noContract
        whenNotPaused
        returns (uint256 shares)
    {
        require(_amount != 0, "INVALID_AMOUNT");

        IStrategy _strategy = strategy;
        require(address(_strategy) != address(0), "NO_STRATEGY");

        uint256 balanceBefore = totalAssets();
        uint256 supply = totalSupply();

        uint256 depositFee = (depositFeeRate.numerator * _amount) /
            depositFeeRate.denominator;
        uint256 amountAfterFee = _amount - depositFee;

        if (supply == 0) {
            shares = amountAfterFee;
        } else {
            //balanceBefore can't be 0 if totalSupply is != 0
            shares = (amountAfterFee * supply) / balanceBefore;
        }

        require(shares != 0, "ZERO_SHARES_MINTED");

        ERC20Upgradeable _token = token;

        if (depositFee != 0)
            _token.safeTransferFrom(msg.sender, feeRecipient, depositFee);
        _token.safeTransferFrom(msg.sender, address(_strategy), amountAfterFee);
        _mint(_to, shares);

        _strategy.deposit();

        emit Deposit(msg.sender, _to, amountAfterFee);
    }

    /// @notice Allows anyone to deposit want tokens from this contract to the strategy.
    function depositBalance() external {
        IStrategy _strategy = strategy;
        require(address(_strategy) != address(0), "NO_STRATEGY");

        ERC20Upgradeable _token = token;

        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "NO_BALANCE");

        _token.safeTransfer(address(_strategy), balance);

        _strategy.deposit();
    }

    /// @notice Allows users to withdraw tokens. Contracts can't call this function
    /// @param _to The address to send the tokens to
    /// @param _shares The amount of shares to burn
    function withdraw(address _to, uint256 _shares)
        external
        noContract
        whenNotPaused
        returns (uint256 backingTokens)
    {
        require(_shares != 0, "INVALID_AMOUNT");

        uint256 supply = totalSupply();
        require(supply != 0, "NO_TOKENS_DEPOSITED");

        uint256 assets = totalAssets();
        backingTokens = (assets * _shares) / supply;
        _burn(msg.sender, _shares);

        ERC20Upgradeable _token = token;
        // Check balance
        uint256 vaultBalance = _token.balanceOf(address(this));
        if (vaultBalance >= backingTokens) {
            _token.safeTransfer(_to, backingTokens);
        } else {
            IStrategy _strategy = strategy;
            assert(address(_strategy) != address(0));

            if (assets - vaultBalance >= backingTokens) {
                _strategy.withdraw(_to, backingTokens);
            } else {
                _token.safeTransfer(_to, vaultBalance);
                _strategy.withdraw(_to, backingTokens - vaultBalance);
            }
        }

        emit Withdrawal(msg.sender, _to, backingTokens);
    }

    /// @notice Allows the owner to migrate strategies.
    /// @param _newStrategy The new strategy. Can be `address(0)`
    function migrateStrategy(IStrategy _newStrategy) external onlyOwner {
        IStrategy _strategy = strategy;
        require(_newStrategy != _strategy, "SAME_STRATEGY");

        if (address(_strategy) != address(0)) {
            _strategy.withdrawAll();
        }
        if (address(_newStrategy) != address(0)) {
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.safeTransfer(address(_newStrategy), balance);
                _newStrategy.deposit();
            }
        }

        strategy = _newStrategy;

        emit StrategyMigrated(_newStrategy, _strategy);
    }

    /// @notice Allows the owner to change fee recipient
    /// @param _newAddress The new fee recipient
    function setFeeRecipient(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "INVALID_ADDRESS");

        emit FeeRecipientChanged(_newAddress, feeRecipient);

        feeRecipient = _newAddress;
    }

    /// @notice Allows the owner to set the deposit fee rate
    /// @param _rate The new rate
    function setDepositFeeRate(Rate memory _rate) public onlyOwner {
        require(
            _rate.denominator != 0 && _rate.denominator > _rate.numerator,
            "INVALID_RATE"
        );
        depositFeeRate = _rate;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Prevent the owner from renouncing ownership. Having no owner would render this contract unusable due to the inability to create new epochs
    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }
}