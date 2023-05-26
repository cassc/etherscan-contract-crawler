//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

  0x67363d3d37363d34f0ff3d5260086017f3:
      0x00  0x68  0x68XXXXXXXXXXXXXXXXXX  PUSH9 bytecode  0x363d3d37363d34f0ff
      0x01  0x3d  0x3d                    RETURNDATASIZE  0 0x363d3d37363d34f0ff
      0x02  0x52  0x52                    MSTORE
      0x03  0x60  0x6009                  PUSH1 09        9
      0x04  0x60  0x6017                  PUSH1 17        23 9
      0x05  0xf3  0xf3                    RETURN

  0x363d3d37363d34f0:
      0x00  0x36  0x36                    CALLDATASIZE    cds
      0x01  0x3d  0x3d                    RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                    RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                    CALLDATACOPY
      0x04  0x36  0x36                    CALLDATASIZE    cds
      0x05  0x3d  0x3d                    RETURNDATASIZE  0 cds
      0x06  0x34  0x34                    CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                    CREATE          addr
      0x08  0xff  0xff                    SELFDESTRUCT
  */

  bytes private constant _PROXY_CHILD_BYTECODE = hex"68_36_3d_3d_37_36_3d_34_f0_ff_3d_52_60_09_60_17_f3";

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 private constant _KECCAK256_PROXY_CHILD_BYTECODE = keccak256(_PROXY_CHILD_BYTECODE); // 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
    // Creation code
    bytes memory creationCode = _PROXY_CHILD_BYTECODE;

    // Get target final address
    addr = addressOf(_salt);
    if (addr.code.length != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    // solhint-disable-next-line no-inline-assembly
    address proxy; assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    // solhint-disable-next-line avoid-low-level-calls
    (bool success,) = proxy.call(_creationCode);
    if (!success || addr.code.length == 0) revert ErrorCreatingContract();
  }

  /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error

    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              _KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
  }
}