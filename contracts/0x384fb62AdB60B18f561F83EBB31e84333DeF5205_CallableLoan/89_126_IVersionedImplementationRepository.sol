// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./IImplementationRepository.sol";

interface IVersionedImplementationRepository is IImplementationRepository {
  function getByVersion(uint8[3] calldata version) external view returns (address);

  function hasVersion(uint8[3] calldata version) external view returns (bool);
}