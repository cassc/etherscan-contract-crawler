// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Vault.sol";
import "../interfaces/IDepositHandler.sol";
import "../interfaces/IVaultFactory.sol";

contract FungibleVestingVault is IDepositHandler, Vault {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public lastVestingTimestamp;

    address[] public tokenAddresses;

    constructor(
        address _vaultKeyContractAddress,
        uint256 _keyId,
        uint256 _vestingEndTimestamp,
        FungibleTokenDeposit[] memory _fungibleTokenDeposits
    ) Vault(_vaultKeyContractAddress, _keyId, _vestingEndTimestamp) {
        for (uint256 i = 0; i < _fungibleTokenDeposits.length; i++) {
            tokenAddresses.push(_fungibleTokenDeposits[i].tokenAddress);
            lastVestingTimestamp[_fungibleTokenDeposits[i].tokenAddress] = block.timestamp;
        }
    }

    function vest() external onlyKeyHolder {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            uint256 amountAvailable = getTokenAvailability(tokenAddresses[i]);
            if (amountAvailable > 0) {
                IERC20(tokenAddresses[i]).safeTransfer(msg.sender, amountAvailable);
                lastVestingTimestamp[tokenAddresses[i]] = block.timestamp;
            }
        }
        isUnlocked = _isCompletelyUnlocked();
        vaultFactoryContract.notifyUnlock(isUnlocked);
    }

    function partialVest(address _tokenAddress) external onlyKeyHolder {
        require(
            _isLockedFungibleAddress(_tokenAddress),
            "FungibleVestingVault:partialFungibleTokenVesting:INVALID_TOKEN"
        );

        uint256 amountAvailable = getTokenAvailability(_tokenAddress);
        IERC20(_tokenAddress).safeTransfer(msg.sender, amountAvailable);

        lastVestingTimestamp[_tokenAddress] = block.timestamp;
        isUnlocked = _isCompletelyUnlocked();
        vaultFactoryContract.notifyUnlock(isUnlocked);
    }

    function getTokenAvailability(address tokenAddress) public view returns (uint256) {
        // Send over all remaining tokens in the case where the unlock
        // timestamp has already expired. Otherwise vest linearly.
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (block.timestamp >= unlockTimestamp) {
            return balance;
        }
        return
            (balance * (block.timestamp - lastVestingTimestamp[tokenAddress])) /
            (unlockTimestamp - lastVestingTimestamp[tokenAddress]);
    }

    function _isCompletelyUnlocked() private view returns (bool) {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (IERC20(tokenAddresses[i]).balanceOf(address(this)) > 0) {
                return false;
            }
        }
        return true;
    }

    function _isLockedFungibleAddress(address _tokenAddress) private view returns (bool) {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (_tokenAddress == tokenAddresses[i]) {
                return true;
            }
        }

        return false;
    }
}