// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./IBaseStrategy.sol";

abstract contract BaseStrategy is IBaseStrategy, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Vars ---
    address public strategist;
    address public destination;
    address public feeRecipient;

    IERC20Upgradeable public underlying;

    bool public PLACEHOLDER_1;

    // --- Events ---
    event UpdatedStrategist(address indexed strategist);
    event UpdatedFeeRecipient(address indexed feeRecipient);

    // --- Init ---
    function __BaseStrategy_init(address _destination, address _feeRecipient, address _underlying) internal onlyInitializing {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        strategist = msg.sender;
        destination = _destination;
        feeRecipient = _feeRecipient;
        underlying = IERC20Upgradeable(_underlying);
    }

    // --- Mods ---
    modifier onlyOwnerOrStrategist() {

        require(msg.sender == owner() || msg.sender == strategist, "BaseStrategy/not-owner-or-strategist");
        _;
    }

    // --- Admin ---
    function setStrategist(address _newStrategist) external onlyOwner {

        require(_newStrategist != address(0));
        strategist = _newStrategist;

        emit UpdatedStrategist(_newStrategist);
    }
    
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        
        require(_newFeeRecipient != address(0));
        feeRecipient = _newFeeRecipient;

        emit UpdatedFeeRecipient(_newFeeRecipient);
    }

    // --- Strategist ---
    function pause() external onlyOwnerOrStrategist {

        _pause();
    }

    function unpause() external onlyOwnerOrStrategist {

        _unpause();
    }

    // --- Internal ---
    function _beforeDeposit(uint256 _amount) internal virtual returns (bool) {}

    // --- Views ---
    function balanceOfWant() public view returns(uint256) {

        return underlying.balanceOf(address(this));
    }
    function balanceOfPool() public view returns(uint256) {

        return underlying.balanceOf(address(destination));
    }
    function balanceOf() public view returns(uint256) {

        return underlying.balanceOf(address(this)) + underlying.balanceOf(address(destination));
    }

    /// @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[45] private __gap;
}