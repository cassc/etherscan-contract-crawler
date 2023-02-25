// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A factory for contract deployment via CREATE2 opcode.
contract Create2Factory is Ownable {
  /// @notice Emits when a new contract is deployed.
  /// @param contractAddress address of created contract.
  event ContractCreated(address contractAddress);

  /// @notice Deploys a contract using CREATE2 opcode.
  /// @param salt a random 'salt' (32 byte string), supplied by the sender;
  /// @param bytecode compiled bytecode of the contract.
  function deploy(bytes32 salt, bytes memory bytecode)
    external
    payable
    onlyOwner
  {
    address contractAddress = Create2.deploy(msg.value, salt, bytecode);

    emit ContractCreated(contractAddress);
  }

  /// @notice Transfers ownership from the factory to the msg.sender
  /// @dev This function is necessary to set the sender as the owner of Ownable contracts that have been
  /// deployed by this factory.
  /// @param contractAddress contract address.
  function setContractOwner(address contractAddress) external onlyOwner {
    Ownable(contractAddress).transferOwnership(_msgSender());
  }

  /// @notice Calculates the address of the contract to be deployed with 'salt' and 'bytecode'.
  function computeAddress(bytes32 salt, bytes32 bytecode)
    external
    view
    returns (address)
  {
    return Create2.computeAddress(salt, bytecode);
  }
}