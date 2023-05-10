// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {
    BitMapsUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import {
    ERC165CheckerUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {
    IERC721Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import { IVerifier } from "./interfaces/IVerifier.sol";
import { IZkpAirdrop } from "./interfaces/IZkpAirdrop.sol";
import { CurrencyManagerUpgradeable } from "./internal-upgradeable/CurrencyManagerUpgradeable.sol";

contract ZkpAirdrop is
    IZkpAirdrop,
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    CurrencyManagerUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using ERC165CheckerUpgradeable for address;

    /// @dev value is equal to keccak256("UPGRADER_ROLE")
    bytes32 public constant UPGRADER_ROLE =
        0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;

    /// @dev value is equal to keccak256("OPERATOR_ROLE")
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;

    IVerifier public verifier;
    mapping(address => address) public treasuries;
    BitMapsUpgradeable.BitMap private _roots;
    BitMapsUpgradeable.BitMap private _nullifierHashes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVerifier verifier_,
        address[] calldata tokens_,
        address[] calldata treasuries_
    ) public initializer {
        address sender = _msgSender();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);
        _grantRole(OPERATOR_ROLE, sender);

        _setVerifier(verifier_);
        _setTreasuries(tokens_, treasuries_);
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function addRoot(uint256 root_) external onlyRole(OPERATOR_ROLE) {
        _addRoot(root_);
    }

    function setVerifier(IVerifier verifier_) external onlyRole(OPERATOR_ROLE) {
        _setVerifier(verifier_);
    }

    function setVaults(
        address[] calldata tokens_,
        address[] calldata vaults_
    ) external onlyRole(OPERATOR_ROLE) {
        _setTreasuries(tokens_, vaults_);
    }

    function isSpent(uint256 nullifierHash_) external view returns (bool) {
        return _nullifierHashes.get(nullifierHash_);
    }

    function withdraw(
        Proof calldata proof_,
        WithdrawInput calldata withdrawInput_
    ) external override nonReentrant whenNotPaused {
        if (withdrawInput_.deadline < block.timestamp) revert ZKPL__Expired();

        if (!_roots.get(withdrawInput_.root)) revert ZKPL__InvalidRoot();

        if (_nullifierHashes.get(withdrawInput_.nullifierHash)) revert ZKPL__AlreadySpent();

        if (!_verifyProof(proof_, withdrawInput_)) {
            revert ZKPL__InvalidProof();
        }

        _nullifierHashes.set(withdrawInput_.nullifierHash);
        _processWithdraw(withdrawInput_.recipient, withdrawInput_.asset, withdrawInput_.value);

        emit Withdrawn(
            withdrawInput_.asset,
            withdrawInput_.recipient,
            withdrawInput_.value,
            withdrawInput_.nullifierHash
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function _addRoot(uint256 root_) private {
        _roots.setTo(root_, true);
        emit RootAdded(root_);
    }

    function _setVerifier(IVerifier verifier_) private {
        if (address(verifier_) == address(0)) revert ZKPL__ZeroAddress();
        emit VerifierUpdated(verifier, verifier_);
        verifier = verifier_;
    }

    function _verifyProof(
        Proof calldata proof_,
        WithdrawInput calldata withdrawInput_
    ) private view returns (bool) {
        return
            verifier.verifyProof(
                proof_.a,
                proof_.b,
                proof_.c,
                [
                    withdrawInput_.root,
                    withdrawInput_.nullifierHash,
                    uint256(uint160(withdrawInput_.recipient)),
                    uint256(uint160(withdrawInput_.asset)),
                    withdrawInput_.value,
                    withdrawInput_.deadline
                ]
            );
    }

    function _setTreasuries(address[] calldata tokens_, address[] calldata treasuries_) private {
        uint256 length = tokens_.length;
        if (length != treasuries_.length) revert ZKPL__LengthMismatch();

        for (uint256 i; i < length; ) {
            treasuries[tokens_[i]] = treasuries_[i];
            unchecked {
                ++i;
            }
        }
    }

    function _processWithdraw(address recipient_, address asset_, uint256 value_) private {
        if ((asset_).supportsInterface(0x80ac58cd)) {
            IERC721Upgradeable(asset_).safeTransferFrom(treasuries[asset_], recipient_, value_);
        } else {
            _transferCurrency(asset_, treasuries[asset_], recipient_, value_);
        }
    }
}