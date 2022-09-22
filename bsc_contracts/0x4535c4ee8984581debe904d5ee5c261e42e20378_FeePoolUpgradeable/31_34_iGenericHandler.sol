// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title GenericHandler contract interface for router Crosstalk
/// @author Router Protocol
interface iGenericHandler {
  struct RouterLinker {
    address _rSyncContract;
    uint8 _chainID;
    address _linkedContract;
  }

  /// @notice MapContract Maps the contract from the RouterCrossTalk Contract
  /// @dev This function is used to map contract from router-crosstalk contract
  /// @param linker The Data object consisting of target Contract , CHainid , Contract to be Mapped and linker type.
  function MapContract(RouterLinker calldata linker) external;

  /// @notice UnMapContract Unmaps the contract from the RouterCrossTalk Contract
  /// @dev This function is used to unmap contract from router-crosstalk contract
  /// @param linker The Data object consisting of target Contract , CHainid , Contract to be unMapped and linker type.
  function UnMapContract(RouterLinker calldata linker) external;

  /// @notice generic deposit on generic handler contract
  /// @dev This function is called by router crosstalk contract while initiating crosschain transaction
  /// @param _destChainID Chain id to be transacted
  /// @param _data Data to be transferred: contains abi encoded selector and data
  /// @param _gasLimit Gas limit specified for the contract function
  /// @param _gasPrice Gas price specified for the contract function
  /// @param _feeToken Fee Token Specified for the contract function
  function genericDeposit(
    uint8 _destChainID,
    bytes calldata _data,
    uint256 _gasLimit,
    uint256 _gasPrice,
    address _feeToken
  ) external returns (uint64);

  /// @notice Fetches ChainID for the native chain
  function fetch_chainID() external view returns (uint8);

  /// @notice Function to replay a transaction which was stuck due to underpricing of gas
  /// @param  _destChainID Destination ChainID
  /// @param  _depositNonce Nonce for the transaction.
  /// @param  _gasLimit Gas limit allowed for the transaction.
  /// @param  _gasPrice Gas Price for the transaction.
  function replayGenericDeposit(
    uint8 _destChainID,
    uint64 _depositNonce,
    uint256 _gasLimit,
    uint256 _gasPrice
  ) external;
}