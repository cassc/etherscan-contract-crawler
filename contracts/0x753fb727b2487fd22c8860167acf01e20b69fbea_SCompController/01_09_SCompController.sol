// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interface/IStrategy.sol";
import "../interface/IConverter.sol";
import "../utility/SCompAccessControl.sol";

contract SCompController is SCompAccessControl {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public rewards;
    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;
    mapping(address => mapping(address => bool)) public approvedStrategies;

    uint256 public constant max = 10000;

    /// @param _governance Can take any permissioned action within the Controller, with the exception of Vault helper functions
    /// @param _strategist Can configure new Vaults, choose strategies among those approved by governance, and call operations involving non-core tokens
    /// @param _rewards The recipient of standard fees (such as performance and withdrawal fees) from Strategies
    constructor(
        address _governance,
        address _strategist,
        address _rewards
    ) {
        governance = _governance;
        strategist = _strategist;
        rewards = _rewards;
    }

    // ===== Modifiers =====

    /// @notice The Sett for a given token or any of the permissioned roles can call earn() to deposit accumulated deposit funds from the Sett to the active Strategy
    function _onlyApprovedForWant(address want) internal view {
        require(msg.sender == vaults[want] || msg.sender == strategist || msg.sender == governance, "!authorized");
    }

    // ===== View Functions =====

    /// @notice Get the balance of the given tokens' current strategy of that token.
    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    // ===== Permissioned Actions: Governance Only =====

    /// @notice Approve the given address as a Strategy for a want. The Strategist can freely switch between approved stratgies for a token.
    function approveStrategy(address _token, address _strategy) public {
        _onlyGovernance();
        approvedStrategies[_token][_strategy] = true;
    }

    /// @notice Revoke approval for the given address as a Strategy for a want.
    function revokeStrategy(address _token, address _strategy) public {
        _onlyGovernance();
        approvedStrategies[_token][_strategy] = false;
    }

    /// @notice Change the recipient of rewards for standard fees from Strategies
    function setRewards(address _rewards) public {
        _onlyGovernance();
        rewards = _rewards;
    }

    // ===== Permissioned Actions: Governance or Strategist =====

    /// @notice Set the Vault (aka Sett) for a given want
    /// @notice The vault can only be set once
    function setVault(address _token, address _vault) public {
        _onlyGovernanceOrStrategist();

        require(vaults[_token] == address(0), "vault");
        vaults[_token] = _vault;
    }

    /// @notice Migrate assets from existing strategy to a new strategy.
    /// @notice The new strategy must have been previously approved by governance.
    /// @notice Strategist or governance can freely switch between approved strategies
    function setStrategy(address _token, address _strategy) public {
        _onlyGovernanceOrStrategist();

        require(approvedStrategies[_token][_strategy] == true, "!approved");

        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    /// @notice Set the contract used to convert between two given assets
    function setConverter(
        address _input,
        address _output,
        address _converter
    ) public {
        _onlyGovernanceOrStrategist();
        converters[_input][_output] = _converter;
    }

    /// @notice Withdraw the entire balance of a token from that tokens' current strategy.
    /// @notice Does not trigger a withdrawal fee.
    /// @notice Entire balance will be sent to corresponding Sett.
    function withdrawAll(address _token) public {
        _onlyGovernanceOrStrategist();
        IStrategy(strategies[_token]).withdrawAll();
    }

    /// @dev Transfer an amount of the specified token from the controller to the sender.
    /// @dev Token balance are never meant to exist in the controller, this is purely a safeguard.
    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        _onlyGovernanceOrStrategist();
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @dev Transfer an amount of the specified token from the controller to the sender.
    /// @dev Token balance are never meant to exist in the controller, this is purely a safeguard.
    function inCaseStrategyTokenGetStuck(address _strategy, address _token) public {
        _onlyGovernanceOrStrategist();
        IStrategy(_strategy).withdrawOther(_token);
    }

    // ==== Permissioned Actions: Only Approved Actors =====

    /// @notice Deposit given token to strategy, converting it to the strategies' want first (if required).
    /// @dev Only the associated vault, or permissioned actors can call this function (strategist, governance)
    /// @param _token Token to deposit (will be converted to want by converter). If no converter is registered, the transaction will revert.
    /// @param _amount Amount of token to deposit
    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).want();

        _onlyApprovedForWant(_want);

        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = IConverter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).deposit();
    }

    // ===== Permissioned Actions: Only Associated Vault =====

    /// @notice Withdraw a given token from it's corresponding strategy
    /// @notice Only the associated vault can call, in response to a user withdrawal request
    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == vaults[_token], "!vault");
        IStrategy(strategies[_token]).withdraw(_amount);
    }
}