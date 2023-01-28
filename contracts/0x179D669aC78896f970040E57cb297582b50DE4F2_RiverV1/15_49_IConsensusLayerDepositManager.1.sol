//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Consensys Layer Deposit Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the interactions with the official deposit contract
interface IConsensusLayerDepositManagerV1 {
    /// @notice A validator key got funded on the deposit contract
    /// @param publicKey BLS Public key that got funded
    event FundedValidatorKey(bytes publicKey);

    /// @notice The stored deposit contract address changed
    /// @param depositContract Address of the deposit contract
    event SetDepositContractAddress(address indexed depositContract);

    /// @notice The stored withdrawal credentials changed
    /// @param withdrawalCredentials The withdrawal credentials to use for deposits
    event SetWithdrawalCredentials(bytes32 withdrawalCredentials);

    /// @notice Not enough funds to deposit one validator
    error NotEnoughFunds();

    /// @notice The length of the BLS Public key is invalid during deposit
    error InconsistentPublicKeys();

    /// @notice The length of the BLS Signature is invalid during deposit
    error InconsistentSignatures();

    /// @notice The internal key retrieval returned no keys
    error NoAvailableValidatorKeys();

    /// @notice The received count of public keys to deposit is invalid
    error InvalidPublicKeyCount();

    /// @notice The received count of signatures to deposit is invalid
    error InvalidSignatureCount();

    /// @notice The withdrawal credentials value is null
    error InvalidWithdrawalCredentials();

    /// @notice An error occured during the deposit
    error ErrorOnDeposit();

    /// @notice Returns the amount of pending ETH
    /// @return The amount of pending ETH
    function getBalanceToDeposit() external view returns (uint256);

    /// @notice Retrieve the withdrawal credentials
    /// @return The withdrawal credentials
    function getWithdrawalCredentials() external view returns (bytes32);

    /// @notice Get the deposited validator count (the count of deposits made by the contract)
    /// @return The deposited validator count
    function getDepositedValidatorCount() external view returns (uint256);

    /// @notice Deposits current balance to the Consensus Layer by batches of 32 ETH
    /// @param _maxCount The maximum amount of validator keys to fund
    function depositToConsensusLayer(uint256 _maxCount) external;
}