// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Marketplace is AccessControl {
  bytes32 public constant TRANSFERER_ROLE = keccak256("TRANSFERER_ROLE");

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(TRANSFERER_ROLE, msg.sender);
  }

  function transferFrom(
    address tokenContractAddress,
    address from,
    address to,
    uint256 tokenId
  ) public onlyRole(TRANSFERER_ROLE) {
    bool isSupport = IERC165(tokenContractAddress).supportsInterface(
      type(IERC721).interfaceId
    );
    require(isSupport, "Not support IERC721");
    IERC721(tokenContractAddress).transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address tokenContractAddress,
    address from,
    address to,
    uint256 tokenId
  ) public onlyRole(TRANSFERER_ROLE) {
    bool isSupport = IERC165(tokenContractAddress).supportsInterface(
      type(IERC721).interfaceId
    );
    require(isSupport, "Not support IERC721");
    IERC721(tokenContractAddress).safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address tokenContractAddress,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public onlyRole(TRANSFERER_ROLE) {
    bool isSupport = IERC165(tokenContractAddress).supportsInterface(
      type(IERC721).interfaceId
    );
    require(isSupport, "Not support IERC721");
    IERC721(tokenContractAddress).safeTransferFrom(from, to, tokenId, data);
  }
}