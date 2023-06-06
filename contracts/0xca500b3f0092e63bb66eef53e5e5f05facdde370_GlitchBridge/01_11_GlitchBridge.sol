// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GlitchBridge is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    ERC20Burnable public glitchToken;

    uint256 public minAmount;
    uint256 public maxAmount;

    /* ========== EVENTS ========== */
    event TransferToGlitch(address indexed from_eth, string _glitchAddress, uint256 _amount);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _tokenAddress, uint256 _minAmount, uint256 _maxAmount) {
        glitchToken = ERC20Burnable(_tokenAddress);
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function transferToGlitch(string memory _glitchAddress, uint256 _amount)
        external
        whenNotPaused
        validateLimits(_amount)
    {
        glitchToken.burnFrom(msg.sender, _amount);

        emit TransferToGlitch(msg.sender, _glitchAddress, _amount);
    }

    function setMinAmount(uint256 _newAmount) external onlyOwner {
        minAmount = _newAmount;
    }

    function setMaxAmount(uint256 _newAmount) external onlyOwner {
        maxAmount = _newAmount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== MODIFIERS ========== */
    modifier validateLimits(uint256 _amount) {
        require(_amount >= minAmount && _amount <= maxAmount, "Invalid amount!");
        _;
    }
}