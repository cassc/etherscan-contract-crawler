// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../interfaces/IDepositHandler.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "../../common/interfaces/IVaultKey.sol";

contract Vault is IDepositHandler, IVault, IERC721Receiver, IERC1155Receiver {
    IVaultFactory public immutable vaultFactoryContract;
    IVaultKey public immutable vaultKeyContract;
    uint256 public immutable vaultKeyId;

    uint256 public immutable lockTimestamp;
    uint256 public unlockTimestamp;
    bool public isUnlocked;

    modifier onlyKeyHolder() {
        require(vaultKeyContract.ownerOf(vaultKeyId) == msg.sender, "Vault:onlyKeyHolder:UNAUTHORIZED");
        _;
    }

    modifier onlyUnlockable() {
        require(block.timestamp >= unlockTimestamp, "Vault:onlyUnlockable:PREMATURE");
        _;
    }

    constructor(
        address _vaultKeyContractAddress,
        uint256 _keyId,
        uint256 _unlockTimestamp
    ) {
        vaultFactoryContract = IVaultFactory(msg.sender);
        vaultKeyContract = IVaultKey(_vaultKeyContractAddress);
        vaultKeyId = _keyId;

        lockTimestamp = block.timestamp;
        unlockTimestamp = _unlockTimestamp;
        isUnlocked = false;
    }

    function extendLock(uint256 newUnlockTimestamp) external onlyKeyHolder {
        require(!isUnlocked, "Vault:extendLock:FULLY_UNLOCKED");
        require(newUnlockTimestamp > unlockTimestamp, "Vault:extendLock:INVALID_TIMESTAMP");
        vaultFactoryContract.lockExtended(unlockTimestamp, newUnlockTimestamp);
        unlockTimestamp = newUnlockTimestamp;
    }

    function getBeneficiary() external view override returns (address) {
        return vaultKeyContract.ownerOf(vaultKeyId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }
}