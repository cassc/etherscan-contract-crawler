// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVenusianGarden {
  function respondToPlantTransfers(
        address origin,
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}