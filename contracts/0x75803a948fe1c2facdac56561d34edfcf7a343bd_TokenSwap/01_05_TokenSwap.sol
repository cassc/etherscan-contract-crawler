// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable, Pausable {
    IERC20 public inputToken;
    uint256 public inputDecimals;
    IERC20 public outputToken;
    uint256 public outputDecimals;
    uint256 public conversionRate;  // conversionRate = output tokens / input tokens

    event Swap(address indexed user, uint256 inputAmount, uint256 outputAmount);
    event WithdrawInputToken(uint256 amount);
    event WithdrawOutputToken(uint256 amount);

    constructor(
        address _inputToken,
        uint256 _inputDecimals,
        address _outputToken,
        uint256 _outputDecimals,
        uint256 _conversionRate
    ) {
        inputToken = IERC20(_inputToken);
        inputDecimals = _inputDecimals;
        outputToken = IERC20(_outputToken);
        outputDecimals = _outputDecimals;
        conversionRate = _conversionRate;
    }

    function swap(uint256 _inputAmount) external whenNotPaused {
        uint256 _outputAmount;

        if (inputDecimals > outputDecimals) {
            _outputAmount = (_inputAmount * conversionRate) / (10**(inputDecimals - outputDecimals));
        } else if (inputDecimals < outputDecimals) {
            _outputAmount = (_inputAmount * conversionRate) * (10**(outputDecimals - inputDecimals));
        } else {
            _outputAmount = _inputAmount * conversionRate;
        }

        // Check if contract has enough output token in its balance
        require(outputToken.balanceOf(address(this)) >= _outputAmount, "Not enough output tokens");

        // Transfer input token from user to contract
        require(inputToken.transferFrom(msg.sender, address(this), _inputAmount), "Input token transfer failed");

        // Transfer output token from contract to user
        require(outputToken.transfer(msg.sender, _outputAmount), "Output token transfer failed");

        emit Swap(msg.sender, _inputAmount, _outputAmount);
    }

    function withdrawInputToken(uint256 _amount) external onlyOwner {
        require(inputToken.transfer(msg.sender, _amount), "Input token withdrawal failed");
    }

    function withdrawOutputToken(uint256 _amount) external onlyOwner {
        require(outputToken.transfer(msg.sender, _amount), "Output token withdrawal failed");
    }

    function setConversionRate(uint256 _newRate) external onlyOwner {
        conversionRate = _newRate;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}