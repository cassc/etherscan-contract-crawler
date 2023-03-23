pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { IDataStructures } from '@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol';

/// @notice Interface to necessary to operate a representative in stakehouse protocol
interface IRepresentative {

    /// @notice Get status about representative verification of the contract
    /// @param _representee - representeee address
    function isRepresentativeApproved(address _representee) external view returns (bool);

    /// @notice Register validator initials for the representative (initial interaction step)
    /// @param _representee - Representee address
    /// @param _blsPublicKey - BLS public key of the representee (knotId)
    /// @param _blsSignature - Signature over the SSZ DepositData container of the Representee
    function registerValidatorInitials(
        address _representee, bytes calldata _blsPublicKey, bytes calldata _blsSignature
    ) external;

    /// @notice Complete deposit for the representative (After initials were registered)
    /// @param _representee - Representee address
    /// @param _blsPublicKey - BLS validation public key
    /// @param _ciphertext - Encryption packet for disaster recovery
    /// @param _aesEncryptorKey - Randomly generated AES key used for BLS signing key encryption
    /// @param _encryptionSignature - ECDSA signature used for encryption validity, issued by committee
    /// @param _dataRoot - Root of the DepositMessage SSZ container
    function registerDeposit(
        address _representee,
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) external payable;

    /// @notice Create stakehouse on behalf of representee
    /// @param _representee - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _ticker - Ticker of the stakehouse to be created
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function createStakehouse(
        address _representee,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Join the house on behalf of representee and get derivative tokens
    /// @param _representee - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _stakehouse - stakehouse address to join
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function joinStakehouse(
        address _representee,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        uint256 _brandTokenId,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;
}