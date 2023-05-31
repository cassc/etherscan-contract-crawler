// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVanillaV1MigrationState, IVanillaV1Converter} from "./interfaces/IVanillaV1Migration01.sol";

/// @title The contract keeping the record of VNL v1 -> v1.1 migration state
contract VanillaV1MigrationState is IVanillaV1MigrationState {

    address private immutable owner;

    /// @inheritdoc IVanillaV1MigrationState
    bytes32 public override stateRoot;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override blockNumber;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override conversionDeadline;

    /// @dev the conversion deadline is initialized to 30 days from the deployment
    /// @param migrationOwner The address of the owner of migration state
    constructor(address migrationOwner) {
        owner = migrationOwner;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier beforeDeadline() {
        if (block.timestamp >= conversionDeadline) {
            revert MigrationStateUpdateDisabled();
        }
        _;
    }

    /// @inheritdoc IVanillaV1MigrationState
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) onlyOwner beforeDeadline external override {
        stateRoot = newStateRoot;
        blockNumber = blockNum;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    /// @inheritdoc IVanillaV1MigrationState
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view override returns (bool) {
        // deliberately using encodePacked with a delimiter string to resolve ambiguity and let client implementations be simpler
        bytes32 leafInTree = keccak256(abi.encodePacked(tokenOwner, ":", amount));
        return block.timestamp < conversionDeadline && MerkleProof.verify(proof, stateRoot, leafInTree);
    }

}

/// @title Conversion functionality for migrating VNL v1 tokens to VNL v1.1
abstract contract VanillaV1Converter is IVanillaV1Converter {
    /// @inheritdoc IVanillaV1Converter
    IVanillaV1MigrationState public override migrationState;
    IERC20 internal vnl;

    constructor(IVanillaV1MigrationState _state, IERC20 _VNLv1) {
        migrationState = _state;
        vnl = _VNLv1;
    }

    function mintConverted(address target, uint256 amount) internal virtual;


    /// @inheritdoc IVanillaV1Converter
    function checkEligibility(bytes32[] memory proof) external view override returns (bool convertible, bool transferable) {
        uint256 balance = vnl.balanceOf(msg.sender);

        convertible = migrationState.verifyEligibility(proof, msg.sender, balance);
        transferable = balance > 0 && vnl.allowance(msg.sender, address(this)) >= balance;
    }

    /// @inheritdoc IVanillaV1Converter
    function convertVNL(bytes32[] memory proof) external override {
        if (block.timestamp >= migrationState.conversionDeadline()) {
            revert ConversionWindowClosed();
        }

        uint256 convertedAmount = vnl.balanceOf(msg.sender);
        if (convertedAmount == 0) {
            revert NoConvertibleVNL();
        }

        // because VanillaV1Token01's cannot be burned, the conversion just locks them into this contract permanently
        address freezer = address(this);
        uint256 previouslyFrozen = vnl.balanceOf(freezer);

        // we know that OpenZeppelin ERC20 returns always true and reverts on failure, so no need to check the return value
        vnl.transferFrom(msg.sender, freezer, convertedAmount);

        // These should never fail as we know precisely how VanillaV1Token01.transferFrom is implemented
        if (vnl.balanceOf(freezer) != previouslyFrozen + convertedAmount) {
            revert FreezerBalanceMismatch();
        }
        if (vnl.balanceOf(msg.sender) > 0) {
            revert UnexpectedTokensAfterConversion();
        }

        if (!migrationState.verifyEligibility(proof, msg.sender, convertedAmount)) {
            revert VerificationFailed();
        }

        // finally let implementor to mint the converted amount of tokens and log the event
        mintConverted(msg.sender, convertedAmount);
        emit VNLConverted(msg.sender, convertedAmount);
    }
}