// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../_external/openzeppelin/OwnableUpgradeable.sol";
import "../../_external/openzeppelin/Initializable.sol";

import {IVaultController} from "../IVaultController.sol";
import {MKRVotingVault} from "../vault/MKRVotingVault.sol";

contract MKRVotingVaultController is Initializable, OwnableUpgradeable {
    error InvalidMKRVotingVault();
    error OnlyCappedToken();

    IVaultController public _vaultController;

    mapping(address => uint96) private _vaultAddress_vaultId; //standard vault addr
    mapping(uint96 => address) private _vaultId_votingVaultAddress;
    mapping(address => uint96) private _votingVaultAddress_vaultId;

    mapping(address => address) public _underlying_CappedToken;
    mapping(address => address) public _CappedToken_underlying;

    event NewMKRVotingVault(address voting_vault_address, uint256 vaultId);

    /// @notice initializer for contract
    /// @param vaultController_ the address of the vault controller
    function initialize(address vaultController_) public initializer {
        __Ownable_init();
        _vaultController = IVaultController(vaultController_);
    }

    /// @notice register an underlying capped token pair
    /// note that registring a token as a capepd token allows it to transfer the balance of the corresponding token at will
    /// @param underlying_address address of underlying
    /// @param capped_token address of capped token
    function registerUnderlying(address underlying_address, address capped_token) external onlyOwner {
        _underlying_CappedToken[underlying_address] = capped_token;
        _CappedToken_underlying[capped_token] = underlying_address;
    }

    /// @notice retrieve underlying asset for the cap token
    /// @param amount of underlying asset to retrieve by burning cap tokens
    /// @param voting_vault holding the underlying
    /// @param target to receive the underlying
    function retrieveUnderlying(
        uint256 amount,
        address voting_vault,
        address target
    ) public {
        if (voting_vault == address(0)) revert InvalidMKRVotingVault();
        address underlying_address = _CappedToken_underlying[_msgSender()];
        if (underlying_address == address(0)) revert OnlyCappedToken();

        MKRVotingVault votingVault = MKRVotingVault(voting_vault);
        votingVault.votingVaultControllerTransfer(underlying_address, target, amount);
    }

    /// @notice create a new vault
    /// @param id of an existing vault
    /// @return address of the new vault
    function mintVault(uint96 id) public returns (address) {
        if (_vaultId_votingVaultAddress[id] == address(0)) {
            address vault_address = _vaultController.vaultAddress(id);
            if (vault_address != address(0)) {
                // mint the vault itself, deploying the contract
                address voting_vault_address = address(
                    new MKRVotingVault(id, vault_address, address(_vaultController), address(this))
                );
                // add the vault to our system
                _vaultId_votingVaultAddress[id] = voting_vault_address;
                _vaultAddress_vaultId[vault_address] = id;
                _votingVaultAddress_vaultId[voting_vault_address] = id;
                // emit the event
                emit NewMKRVotingVault(voting_vault_address, id);
            }
        }
        return _vaultId_votingVaultAddress[id];
    }

    function votingVaultId(address voting_vault_address) public view returns (uint96) {
        return _votingVaultAddress_vaultId[voting_vault_address];
    }

    function vaultId(address vault_address) public view returns (uint96) {
        return _vaultAddress_vaultId[vault_address];
    }

    function votingVaultAddress(uint96 vault_id) public view returns (address) {
        return _vaultId_votingVaultAddress[vault_id];
    }
}