// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SBINFTForwarder is
  Initializable,
  EIP712Upgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  using ECDSAUpgradeable for bytes32;
  struct ForwardRequest {
    address from;
    address to;
    uint256 value;
    uint256 gas;
    uint256 nonce;
    bytes data;
  }
  bytes32 private constant FORWARD_REQUEST_TYPEHASH =
    keccak256(
      "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
    );

  function __SBINFTForwarder_init() external initializer {
    __Ownable_init();
    __EIP712_init("SBINFTForwarder", "1.0");
    __UUPSUpgradeable_init();
  }

  /**
   * @dev See {UUPSUpgradeable._authorizeUpgrade()}
   *
   * @param newImplementation address
   *
   * Requirements:
   * - onlyOwner can call
   */
  function _authorizeUpgrade(address newImplementation)
    internal
    virtual
    override
    onlyOwner
  {}

  /**
   * @dev This function verift the _signature and return the result.
   *
   * @param req ForwardRequest calldata
   * @param signature bytes calldata
   *
   * @return True if the _signature is valid, Otherwise False.
   */
  function verify(ForwardRequest calldata req, bytes calldata signature)
    public
    view
    returns (bool)
  {
    address recoverdAddress = _hashTypedDataV4(
      keccak256(
        abi.encode(
          FORWARD_REQUEST_TYPEHASH,
          req.from,
          req.to,
          req.value,
          req.gas,
          req.nonce,
          keccak256(req.data)
        )
      )
    ).recover(signature);
    return recoverdAddress == req.from;
  }

  /**
   * @dev Forward the transaction request to the desination contract.
   *
   * @param req ForwardRequest calldata
   * @param signature bytes calldata
   */
  function execute(ForwardRequest calldata req, bytes calldata signature)
    public
    payable
    returns (bool, bytes memory)
  {
    require(
      verify(req, signature),
      "SBINFTForwarder: signature does not match request"
    );

    require(msg.value >= req.value, "SBINFTForwarder: not enough ETH sent");

    (bool success, bytes memory returndata) = req.to.call{
      gas: req.gas,
      value: req.value
    }(abi.encodePacked(req.data, req.from));

    if (success == false) {
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        /// @solidity memory-safe-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert("SBINFTForwarder: failed to execute");
      }
    }

    // Validate that the relayer has sent enough gas for the call.
    // See https://ronan.eth.link/blog/ethereum-gas-dangers/
    if (gasleft() <= req.gas / 63) {
      // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
      // neither revert or assert consume all gas since Solidity 0.8.0
      // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
      /// @solidity memory-safe-assembly
      assembly {
        invalid()
      }
    }

    return (success, returndata);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}