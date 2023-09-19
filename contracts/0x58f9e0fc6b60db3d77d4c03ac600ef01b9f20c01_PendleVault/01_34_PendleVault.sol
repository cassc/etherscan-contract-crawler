//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../../interfaces/ILiquidityGaugeStrat.sol";
import "./PendleStrategy.sol";

contract PendleVault is ERC20Upgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using AddressUpgradeable for address;

    error GAUGE_NOT_SET();
    error NOT_ALLOWED();
    error NOT_ENOUGH_STAKED();

    address constant LOCKER = 0xD8fa8dC5aDeC503AcC5e026a98F32Ca5C1Fa289A;
    ERC20Upgradeable public token;
    address public governance;
    ILiquidityGaugeStrat public liquidityGauge;
    PendleStrategy public strategy;

    event Deposit(address _depositor, uint256 _amount);
    event GovernanceSet(address _oldG, address _newG);
    event LiquidityGaugeSet(address _oldLg, address _newLg);
    event StrategySet(address _oldS, address _newS);
    event Withdraw(address _depositor, uint256 _amount);

    function init(
        ERC20Upgradeable _token,
        address _governance,
        string memory name_,
        string memory symbol_,
        PendleStrategy _pendleStrategy
    ) public initializer {
        __ERC20_init(name_, symbol_);
        token = _token;
        governance = _governance;
        strategy = _pendleStrategy;
    }

    /// @notice function to deposit pendle lpt tokens
    /// @param _staker address to deposit for
    /// @param _amount amount to deposit
    function deposit(address _staker, uint256 _amount) external {
        if (address(liquidityGauge) == address(0)) revert GAUGE_NOT_SET();
        // transfer LPT to the locker to be hold
        token.safeTransferFrom(msg.sender, LOCKER, _amount);
        // mint the same amount of sd LP and stake it to the gauge
        _mint(address(this), _amount);
        liquidityGauge.deposit(_amount, _staker);
        emit Deposit(_staker, _amount);
    }

    /// @notice function to withdraw pendle lpt tokens
    /// @param _amount amount to withdraw
    function withdraw(uint256 _amount) public {
        uint256 userAmount = liquidityGauge.balanceOf(msg.sender);
        if (_amount > userAmount) revert NOT_ENOUGH_STAKED();
        // withdraw the token and collect rewards
        liquidityGauge.withdraw(_amount, msg.sender, true);
        _burn(address(this), _amount);
        strategy.withdraw(address(token), _amount, msg.sender);
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice function to withdraw all user's pendle lpt tokens deposited 
    function withdrawAll() external {
        withdraw(liquidityGauge.balanceOf(msg.sender));
    }

    /// @notice function to set the governance
    /// @param _governance governance address
    function setGovernance(address _governance) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit GovernanceSet(governance, _governance);
        governance = _governance;
    }
    
    /// @notice function to set the liquidity gauge
    /// @param _liquidityGauge gauge address
    function setLiquidityGauge(address _liquidityGauge) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        // it will do an infinite approve to deposit token from here 
        ERC20Upgradeable(address(this)).approve(_liquidityGauge, type(uint256).max);
        emit LiquidityGaugeSet(address(liquidityGauge), _liquidityGauge);
        liquidityGauge = ILiquidityGaugeStrat(_liquidityGauge);
    }

    /// @notice function to set the pendle strategy
    /// @param _strategy strategy address
    function setPendleStrategy(address _strategy) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit StrategySet(address(strategy), _strategy);
        strategy = PendleStrategy(_strategy);
    }

    /// @notice function to get the sdToken decimals
    function decimals() public view override returns (uint8) {
        return token.decimals();
    } 
}