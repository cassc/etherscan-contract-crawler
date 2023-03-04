//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { IChainLog } from "../../interfaces/maker/IChainLog.sol";

/**
 * @title ChainLogView
 * @notice Reads the Chainlog contract to get the address of a service by its name
 */
contract ChainLogView {
  address public immutable chainlogAddress;

  constructor(address _chainlogAddress) {
    chainlogAddress = _chainlogAddress;
  }

  /**
   * @notice Gets the string representation of a bytes32 value with `-` replaced with `_`
   * @param _bytes32 value to decode to string
   * @return The decoded string
   */
  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      if (_bytes32[i] == bytes1("-")) {
        bytesArray[i] = bytes1("_");
      } else {
        bytesArray[i] = _bytes32[i];
      }
    }
    return string(bytesArray);
  }

  /**
   * @notice Gets the address of a service by its name
   * @param serviceName The name of the service
   * @return The address of the service
   */

  function getServiceAddress(string calldata serviceName) public view returns (address) {
    bytes32 serviceHash = bytes32(abi.encodePacked(serviceName));
    return IChainLog(chainlogAddress).getAddress(serviceHash);
  }

  /**
   * @notice Gets the address of a join adapter by its ilk name
   * @param ilkName The name of the ilk
   * @return The address of the join adapter
   */
  function getIlkJoinAddressByName(string calldata ilkName) public view returns (address) {
    bytes32 ilkHash = bytes32(abi.encodePacked("MCD_JOIN_", ilkName));
    return IChainLog(chainlogAddress).getAddress(ilkHash);
  }

  /**
   * @notice Gets the address of a join adapter by its ilk hash
   * @param ilkHash The hash of the ilk name
   * @return The address of the join adapter
   */
  function getIlkJoinAddressByHash(bytes32 ilkHash) public view returns (address) {
    bytes32 newIlkHash = bytes32(abi.encodePacked("MCD_JOIN_", bytes32ToString(ilkHash)));
    return IChainLog(chainlogAddress).getAddress(newIlkHash);
  }
}