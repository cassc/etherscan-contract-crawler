// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMintValidator.sol";

interface IFabricator {
    function modularMintInit(
    uint256 _dropId,
    address _to,
    uint256[] memory _requestedAmounts,
    bytes memory _data,
    IMintValidator _validator,
    string calldata _metadata
  ) external;
    function modularMintCallback(
    address recipient,
    uint256[] memory _ids,
    uint256[] memory _requestedAmounts,
    bytes memory _data
  ) external;
  function quantityMinted(uint256 collectibleId) external returns(uint256);
}