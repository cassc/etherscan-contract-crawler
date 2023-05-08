// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CpTHENASwapper is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public cpTHENA;
    address public chamTHE; 

    event Deposit(uint256 amount);
    event OldAddress(address _cpTHENA, address _chamTHE);
    
    function initialize(address _cpTHENA, address _chamTHE) public initializer {
        __Ownable_init();
        cpTHENA = _cpTHENA;
        chamTHE = _chamTHE;
    }

    function deposit(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Swap: ZERO_AMOUNT");
        IERC20Upgradeable(chamTHE).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Upgradeable(cpTHENA).safeTransfer(msg.sender, _amount);
        
        emit Deposit(_amount);
    }

    function adminWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
    }

    function setAddress(address _cpTHENA, address _chamTHE) external onlyOwner {
        emit OldAddress(address(cpTHENA), address(chamTHE));
        cpTHENA = _cpTHENA;
        chamTHE = _chamTHE;
    }
}