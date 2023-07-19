// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IVault} from "../IVault.sol";
import {IVaultController} from "../IVaultController.sol";
import "../../_external/IERC20.sol";
import "../../_external/IERC20.sol";
import "../../_external/Context.sol";
import "../../_external/openzeppelin/SafeERC20Upgradeable.sol";

import {MKRLike} from "../../_external/MKRLike.sol";
import {MKRVotingVaultController} from "../controller/MKRVotingVaultController.sol";

interface TokenLike_1 {
    function approve(address, uint256) external returns (bool);
}

interface VoteDelegate {
    function iou() external view returns (TokenLike_1);

    function stake(address staker) external view returns (uint256);
}

contract MKRVotingVault is Context {
    using SafeERC20Upgradeable for IERC20;

    error OnlyMinter();
    error OnlyMKRVotingVaultController();
    error OnlyVaultController();

    /// @title MKRVotingVault 
    /// @notice This vault holds the underlying token
    /// @notice The Capped token is held by the parent vault
    /// @notice Withdrawls must be initiated by the withdrawErc20() function on the parent vault

    /// @notice this struct is used to store the vault metadata
    /// this should reduce the cost of minting by ~15,000
    /// by limiting us to max 2**96-1 vaults
    struct VaultInfo {
        uint96 id;
        address vault_address;
    }

    /// @notice Metadata of vault, aka the id & the minter's address
    VaultInfo private _vaultInfo;

    MKRVotingVaultController public _mkrVotingVaultController;
    IVaultController public _vaultController;

    /// @notice checks if _msgSender is the controller of the voting vault
    modifier onlyMKRVotingVaultController() {
        if (_msgSender() != address(_mkrVotingVaultController)) revert OnlyMKRVotingVaultController();
        _;
    }
    /// @notice checks if _msgSender is the controller of the vault
    modifier onlyVaultController() {
        if (_msgSender() != address(_vaultController)) revert OnlyVaultController();
        _;
    }
    /// @notice checks if _msgSender is the minter of the vault
    modifier onlyMinter() {
        if (_msgSender() != IVault(_vaultInfo.vault_address).minter()) revert OnlyMinter();
        _;
    }

    /// @notice must be called by MKRVotingVaultController, else it will not be registered as a vault in the system
    /// @param id_ is the shared ID of both the voting vault and the standard vault
    /// @param vault_address address of the vault this is attached to
    /// @param controller_address address of the VaultController
    /// @param voting_controller_address address of the MKRVotingVaultController
    constructor(
        uint96 id_,
        address vault_address,
        address controller_address,
        address voting_controller_address
    ) {
        _vaultInfo = VaultInfo(id_, vault_address);
        _vaultController = IVaultController(controller_address);
        _mkrVotingVaultController = MKRVotingVaultController(voting_controller_address);
    }

    function parentVault() external view returns (address) {
        return address(_vaultInfo.vault_address);
    }

    function id() external view returns (uint96) {
        return _vaultInfo.id;
    }

    function delegateMKRLikeTo(
        address delegatee,
        address tokenAddress,
        uint256 amount
    ) external onlyMinter {
        IERC20(tokenAddress).approve(delegatee, amount);
        MKRLike(delegatee).lock(amount);
    }

    function undelegateMKRLike(address delegatee, uint256 amount) external onlyMinter {
        TokenLike_1 iou = VoteDelegate(delegatee).iou();
        iou.approve(delegatee, amount);
        MKRLike(delegatee).free(amount);
    }

    /// @notice function used by the VaultController to transfer tokens
    /// callable by the VaultController only
    /// not currently in use, available for future upgrades
    /// @param _token token to transfer
    /// @param _to person to send the coins to
    /// @param _amount amount of coins to move
    function controllerTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyVaultController {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _to, _amount);
    }

    /// @notice function used by the MKRVotingVaultController to transfer tokens
    /// callable by the MKRVotingVaultController only
    /// @param _token token to transfer
    /// @param _to person to send the coins to
    /// @param _amount amount of coins to move
    function votingVaultControllerTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyMKRVotingVaultController {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _to, _amount);
    }
}