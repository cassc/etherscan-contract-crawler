// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./Vault.sol";
import "../../common/interfaces/INonfungiblePositionManager.sol";
import "../interfaces/IVaultFactory.sol";

contract MultiVault is Vault {
    using SafeERC20 for IERC20;

    FungibleTokenDeposit[] public fungibleTokenDeposits;
    NonFungibleTokenDeposit[] public nonFungibleTokenDeposits;
    MultiTokenDeposit[] public multiTokenDeposits;

    constructor(
        address _vaultKeyContractAddress,
        uint256 _keyId,
        uint256 _unlockTimestamp,
        FungibleTokenDeposit[] memory _fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory _nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory _multiTokenDeposits
    ) Vault(_vaultKeyContractAddress, _keyId, _unlockTimestamp) {
        for (uint256 i = 0; i < _fungibleTokenDeposits.length; i++) {
            fungibleTokenDeposits.push(_fungibleTokenDeposits[i]);
        }

        for (uint256 i = 0; i < _nonFungibleTokenDeposits.length; i++) {
            nonFungibleTokenDeposits.push(_nonFungibleTokenDeposits[i]);
        }

        for (uint256 i = 0; i < _multiTokenDeposits.length; i++) {
            multiTokenDeposits.push(_multiTokenDeposits[i]);
        }
    }

    /// @notice Collects the fees associated with provided liquidity
    /// The contract must hold the erc721 token before it can collect fees
    function collectV3PositionFees(address tokenAddress, uint256 tokenId) external onlyKeyHolder {
        // set amount0Max and amount1Max to uint256.max to collect all fees
        INonfungiblePositionManager(tokenAddress).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(msg.sender),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    /// @notice Collects the fees associated with provided liquidity
    /// The contract must hold the erc721 token before it can collect fees
    function reinvestV3PositionFees(address tokenAddress, uint256 tokenId) external onlyKeyHolder {
        // set amount0Max and amount1Max to uint256.max to collect all fees
        INonfungiblePositionManager(tokenAddress).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function unlock(bytes memory data) external onlyKeyHolder onlyUnlockable {
        require(!isUnlocked, "MultiVault:unlock:ALREADY_OPEN: Vault has already been unlocked");

        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            IERC20 token = IERC20(fungibleTokenDeposits[i].tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            // in case a token is duplicated, only one transfer is required, hence the check
            if (balance > 0) {
                token.safeTransfer(msg.sender, balance);
            }
        }

        for (uint256 i = 0; i < nonFungibleTokenDeposits.length; i++) {
            IERC721(nonFungibleTokenDeposits[i].tokenAddress).safeTransferFrom(
                address(this),
                msg.sender,
                nonFungibleTokenDeposits[i].tokenId
            );
        }

        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            IERC1155(multiTokenDeposits[i].tokenAddress).safeTransferFrom(
                address(this),
                msg.sender,
                multiTokenDeposits[i].tokenId,
                multiTokenDeposits[i].amount,
                data
            );
        }

        isUnlocked = true;
        vaultFactoryContract.notifyUnlock(true);
    }

    function partialFungibleTokenUnlock(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyKeyHolder
        onlyUnlockable
    {
        require(_isLockedFungibleAddress(_tokenAddress), "MultiVault:partialFungibleTokenUnlock:INVALID_TOKEN");

        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        vaultFactoryContract.notifyUnlock(_isCompletelyUnlocked());
    }

    function partialNonFungibleTokenUnlock(address _tokenAddress, uint256 _tokenId)
        external
        onlyKeyHolder
        onlyUnlockable
    {
        require(_isLockedNonFungibleAddress(_tokenAddress), "MultiVault:partialNonFungibleTokenUnlock:INVALID_TOKEN");

        IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

        vaultFactoryContract.notifyUnlock(_isCompletelyUnlocked());
    }

    function partialMultiTokenUnlock(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        bytes calldata data
    ) external onlyKeyHolder onlyUnlockable {
        require(_isLockedMultiAddress(_tokenAddress), "MultiVault:partialMultiTokenUnlock:INVALID_TOKEN");

        IERC1155(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _tokenAmount, data);

        vaultFactoryContract.notifyUnlock(_isCompletelyUnlocked());
    }

    function _isLockedFungibleAddress(address _tokenAddress) private view returns (bool) {
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            if (_tokenAddress == fungibleTokenDeposits[i].tokenAddress) {
                return true;
            }
        }

        return false;
    }

    function _isLockedNonFungibleAddress(address _tokenAddress) private view returns (bool) {
        for (uint256 i = 0; i < nonFungibleTokenDeposits.length; i++) {
            if (_tokenAddress == nonFungibleTokenDeposits[i].tokenAddress) {
                return true;
            }
        }

        return false;
    }

    function _isLockedMultiAddress(address _tokenAddress) private view returns (bool) {
        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            if (_tokenAddress == multiTokenDeposits[i].tokenAddress) {
                return true;
            }
        }

        return false;
    }

    function _isCompletelyUnlocked() private view returns (bool) {
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            if (IERC20(fungibleTokenDeposits[i].tokenAddress).balanceOf(address(this)) > 0) {
                return false;
            }
        }

        for (uint256 i = 0; i < nonFungibleTokenDeposits.length; i++) {
            if (IERC721(nonFungibleTokenDeposits[i].tokenAddress).balanceOf(address(this)) > 0) {
                return false;
            }
        }

        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            MultiTokenDeposit memory deposit = multiTokenDeposits[i];

            if (IERC1155(deposit.tokenAddress).balanceOf(address(this), deposit.tokenId) > 0) {
                return false;
            }
        }

        return true;
    }
}