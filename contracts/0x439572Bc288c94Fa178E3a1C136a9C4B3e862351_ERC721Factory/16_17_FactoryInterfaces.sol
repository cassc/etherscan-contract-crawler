// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1155Factory {
  function createERC1155(address owner) external;
}

interface IERC721Factory {
  function createERC721(address owner) external;
}

interface IERC721AMintableFactory {
  function createERC721AMintable(
    address _stars,
    address _owner,
    bool _ethAllowed,
    bool _starsAllowed,
    uint256[] memory ethPrices,
    uint256[] memory starsPrices
  ) external;
}

interface IInitializableERC1155 {
  function init(address _owner) external;
}

interface IInitializableERC721 {
  function init(address _owner) external;
}

interface IInitializableERC721AMintable {
  function init(
    address _stars,
    address _owner,
    bool _ethAllowed,
    bool _starsAllowed,
    uint256[] memory ethPrices,
    uint256[] memory starsPrices
  ) external;
}