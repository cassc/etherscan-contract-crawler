// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { CollateralType, Fee } from "./lib/Structs.sol";
import { InvalidCollateralType } from "./lib/Errors.sol";


contract SafeTransfer {
  using SafeERC20 for IERC20;

  function transfer(
    uint8 collateralType,
    address token,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) internal {
    if (
      collateralType == uint8(CollateralType.ERC721) ||
      collateralType == uint8(CollateralType.ERC721_WITH_CRITERIA)
    ) {
      return _transferERC721(token, from, to, tokenId);
    } else if (
      collateralType == uint8(CollateralType.ERC1155) ||
      collateralType == uint8(CollateralType.ERC1155_WITH_CRITERIA)
    ) {
      return _transferERC1155(token, from, to, tokenId, amount);
    }
    revert InvalidCollateralType();
  }

  function _transferERC721(
    address token,
    address from,
    address to,
    uint256 tokenId
  ) internal {
    IERC721(token).safeTransferFrom(from, to, tokenId, "0x");
  }

  function _transferERC1155(
    address token,
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) internal {
    IERC1155(token).safeTransferFrom(from, to, id, amount, "0x");
  }

  function transferERC20(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    IERC20(token).transferFrom(from, to, amount);
  }
}