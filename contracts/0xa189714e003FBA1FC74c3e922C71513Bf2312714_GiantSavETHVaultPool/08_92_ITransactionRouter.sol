pragma solidity ^0.8.10;

import { IDataStructures } from './IDataStructures.sol';

// SPDX-License-Identifier: BUSL-1.1

interface ITransactionRouter {
    /// @notice Fetch representative to representee status
    /// @param _user - User checked for representation
    /// @param _representative - Address representing the user
    function userToRepresentativeStatus(address _user, address _representative) external view returns (bool);

    /// @notice Signaling added representative
    event RepresentativeAdded(address indexed user, address indexed representative);

    /// @notice Signaling removed representative
    event RepresentativeRemoved(address indexed user, address indexed representative);

    /// @notice Select representative address to perform staking actions for you
    /// @param _representative - Address representing the user in the staking process
    /// @param _enabled Whether they are being activated or deactivated
    function authorizeRepresentative(address _representative, bool _enabled) external;

    /// @notice First user interaction in the process of registering validator
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    function registerValidatorInitials(
        address _user, bytes calldata _blsPublicKey, bytes calldata _blsSignature
    ) external;

    /// @notice function to register the ETH2 validator by depositing 32ETH to EF deposit contract
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS validation public key
    /// @param _ciphertext - Encryption packet for disaster recovery
    /// @param _aesEncryptorKey - Randomly generated AES key used for BLS signing key encryption
    /// @param _encryptionSignature - ECDSA signature used for encryption validity, issued by committee
    /// @param _dataRoot - Root of the DepositMessage SSZ container
    function registerValidator(
        address _user,
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) external payable;

    /// @notice Adapter call to core for stakehouse creation
    /// @notice Direct extension for the function in AccountManager
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _ticker - Ticker of the stakehouse to be created
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function createStakehouse(
        address _user,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Join the house and get derivative tokens
    /// @notice Direct extension for the function in AccountManager
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _stakehouse - stakehouse address to join
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function joinStakehouse(
        address _user,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        uint256 _brandTokenId,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Join the house and get derivative tokens + create the brand
    /// @notice Direct extension for the function in AccountManager
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _ticker - Ticker of the stakehouse
    /// @param _stakehouse - Stakehouse address the user wants to join
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function joinStakeHouseAndCreateBrand(
        address _user,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        address _stakehouse,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Enable a user that has deposited through checkpoint A to exit via an escape hatch before even minting their derivative tokens
    /// @param _blsPublicKey Validator public key
    /// @param _stakehouse House to rage quit against
    /// @param _eth2Report Beacon chain report showing last known state of the validator
    /// @param _reportSignature Signature over the ETH 2 data report packet
    function rageQuitPostDeposit(
        address _user,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;
}