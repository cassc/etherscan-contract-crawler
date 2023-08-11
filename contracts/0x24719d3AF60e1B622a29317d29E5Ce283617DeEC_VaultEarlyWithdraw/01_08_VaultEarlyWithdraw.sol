pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVault {
    function toTokenAmount(uint256 sharesAmount) external view returns (uint256 tokenAmount);
}

/// @notice Allow a user to withdraw Temple from a vault early,
// by swapping vaulted Temple for pre-funded un-vaulted Temple.
contract VaultEarlyWithdraw is Pausable, Ownable {
    using SafeERC20 for IERC20;

    IERC20 immutable public templeToken;
    mapping(address => bool) public validVaults;

    // @notice Enforce a minimum withdraw amount to circumvent very small rounding issues on exit
    uint256 public minWithdrawAmount = 1_000;

    event TokenRecovered(address indexed token, address indexed to, uint256 amount);
    event EarlyWithdraw(address indexed addr, uint256 amount);
    event MinWithdrawAmountSet(uint256 amount);

    error MinAmountNotMet();
    error InvalidVault(address _vaultAddress);
    error InvalidAddress(address _addr);
    error SendFailed();
    
    constructor(address _templeTokenAddress, address[] memory _validVaults) {
        templeToken = IERC20(_templeTokenAddress);

        for (uint256 i=0; i<_validVaults.length; ++i) {
            validVaults[_validVaults[i]] = true;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMinWithdrawAmount(uint256 amount) external onlyOwner {
        minWithdrawAmount = amount;
        emit MinWithdrawAmountSet(amount);
    }

    /**
     * @notice User with vaulted token in one of the whitelisted vaults can withdraw early.
     */
    function withdraw(address _vault, uint256 _templeAmount) external whenNotPaused {
        if (!validVaults[_vault]) revert InvalidVault(_vault);
        if (_templeAmount < minWithdrawAmount) revert MinAmountNotMet();

        // Pull the user's vaulted temple, and send to the owner
        IERC20(_vault).safeTransferFrom(msg.sender, owner(), _templeAmount);

        // Send un-vaulted $TEMPLE, pre-funded into this contract, to sender.
        templeToken.safeTransfer(msg.sender, _templeAmount);

        emit EarlyWithdraw(msg.sender, _templeAmount);
    }

    /**
     * @notice Owner can recover token, including any left over $TEMPLE
     */
    function recoverToken(address token, address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert InvalidAddress(to);
        IERC20(token).safeTransfer(to, amount);
        emit TokenRecovered(token, to, amount);
    }
}