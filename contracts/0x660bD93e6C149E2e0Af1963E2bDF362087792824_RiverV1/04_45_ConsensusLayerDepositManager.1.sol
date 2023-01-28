//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/IConsensusLayerDepositManager.1.sol";
import "../interfaces/IDepositContract.sol";

import "../libraries/LibBytes.sol";
import "../libraries/LibUint256.sol";

import "../state/river/DepositContractAddress.sol";
import "../state/river/WithdrawalCredentials.sol";
import "../state/river/DepositedValidatorCount.sol";
import "../state/river/BalanceToDeposit.sol";

/// @title Consensus Layer Deposit Manager (v1)
/// @author Kiln
/// @notice This contract handles the interactions with the official deposit contract, funding all validators
/// @notice Whenever a deposit to the consensus layer is requested, this contract computed the amount of keys
/// @notice that could be deposited depending on the amount available in the contract. It then tries to retrieve
/// @notice validator keys by calling its internal virtual method _getNextValidators. This method should be
/// @notice overridden by the implementing contract to provide [0; _keyCount] keys when invoked.
abstract contract ConsensusLayerDepositManagerV1 is IConsensusLayerDepositManagerV1 {
    /// @notice Size of a BLS Public key in bytes
    uint256 public constant PUBLIC_KEY_LENGTH = 48;
    /// @notice Size of a BLS Signature in bytes
    uint256 public constant SIGNATURE_LENGTH = 96;
    /// @notice Size of a deposit in ETH
    uint256 public constant DEPOSIT_SIZE = 32 ether;

    /// @notice Handler called to retrieve the internal River admin address
    /// @dev Must be overriden
    function _getRiverAdmin() internal view virtual returns (address);

    /// @notice Prevents unauthorized calls
    modifier onlyAdmin_CDMV1() {
        if (msg.sender != _getRiverAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Internal helper to retrieve validator keys ready to be funded
    /// @dev Must be overridden
    /// @param _keyCount The amount of keys (or less) to return.
    function _getNextValidators(uint256 _keyCount)
        internal
        virtual
        returns (bytes[] memory publicKeys, bytes[] memory signatures);

    /// @notice Initializer to set the deposit contract address and the withdrawal credentials to use
    /// @param _depositContractAddress The address of the deposit contract
    /// @param _withdrawalCredentials The withdrawal credentials to apply to all deposits
    function initConsensusLayerDepositManagerV1(address _depositContractAddress, bytes32 _withdrawalCredentials)
        internal
    {
        DepositContractAddress.set(_depositContractAddress);
        emit SetDepositContractAddress(_depositContractAddress);

        WithdrawalCredentials.set(_withdrawalCredentials);
        emit SetWithdrawalCredentials(_withdrawalCredentials);
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function getBalanceToDeposit() external view returns (uint256) {
        return BalanceToDeposit.get();
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function getWithdrawalCredentials() external view returns (bytes32) {
        return WithdrawalCredentials.get();
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function getDepositedValidatorCount() external view returns (uint256) {
        return DepositedValidatorCount.get();
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function depositToConsensusLayer(uint256 _maxCount) external onlyAdmin_CDMV1 {
        uint256 balanceToDeposit = BalanceToDeposit.get();
        uint256 keyToDepositCount = LibUint256.min(balanceToDeposit / DEPOSIT_SIZE, _maxCount);

        if (keyToDepositCount == 0) {
            revert NotEnoughFunds();
        }

        (bytes[] memory publicKeys, bytes[] memory signatures) = _getNextValidators(keyToDepositCount);

        uint256 receivedPublicKeyCount = publicKeys.length;

        if (receivedPublicKeyCount == 0) {
            revert NoAvailableValidatorKeys();
        }

        if (receivedPublicKeyCount > keyToDepositCount) {
            revert InvalidPublicKeyCount();
        }

        uint256 receivedSignatureCount = signatures.length;

        if (receivedSignatureCount != receivedPublicKeyCount) {
            revert InvalidSignatureCount();
        }

        bytes32 withdrawalCredentials = WithdrawalCredentials.get();

        if (withdrawalCredentials == 0) {
            revert InvalidWithdrawalCredentials();
        }

        for (uint256 idx = 0; idx < receivedPublicKeyCount;) {
            _depositValidator(publicKeys[idx], signatures[idx], withdrawalCredentials);
            unchecked {
                ++idx;
            }
        }
        BalanceToDeposit.set(balanceToDeposit - DEPOSIT_SIZE * receivedPublicKeyCount);
        DepositedValidatorCount.set(DepositedValidatorCount.get() + receivedPublicKeyCount);
    }

    /// @notice Deposits 32 ETH to the official Deposit contract
    /// @param _publicKey The public key of the validator
    /// @param _signature The signature provided by the operator
    /// @param _withdrawalCredentials The withdrawal credentials provided by River
    function _depositValidator(bytes memory _publicKey, bytes memory _signature, bytes32 _withdrawalCredentials)
        internal
    {
        if (_publicKey.length != PUBLIC_KEY_LENGTH) {
            revert InconsistentPublicKeys();
        }

        if (_signature.length != SIGNATURE_LENGTH) {
            revert InconsistentSignatures();
        }
        uint256 value = DEPOSIT_SIZE;

        uint256 depositAmount = value / 1 gwei;

        bytes32 pubkeyRoot = sha256(bytes.concat(_publicKey, bytes16(0)));
        bytes32 signatureRoot = sha256(
            bytes.concat(
                sha256(LibBytes.slice(_signature, 0, 64)),
                sha256(bytes.concat(LibBytes.slice(_signature, 64, SIGNATURE_LENGTH - 64), bytes32(0)))
            )
        );

        bytes32 depositDataRoot = sha256(
            bytes.concat(
                sha256(bytes.concat(pubkeyRoot, _withdrawalCredentials)),
                sha256(bytes.concat(bytes32(LibUint256.toLittleEndian64(depositAmount)), signatureRoot))
            )
        );

        uint256 targetBalance = address(this).balance - value;

        IDepositContract(DepositContractAddress.get()).deposit{value: value}(
            _publicKey, abi.encodePacked(_withdrawalCredentials), _signature, depositDataRoot
        );
        if (address(this).balance != targetBalance) {
            revert ErrorOnDeposit();
        }
        emit FundedValidatorKey(_publicKey);
    }
}