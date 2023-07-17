// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDelegate is Ownable {
  error Unauthorized();

  // Whether an address is allowed to call `spendFrom()`.
  mapping(address => bool) public authorized;

  modifier onlyAuthorized() {
    if (authorized[msg.sender] == false) {
      revert Unauthorized();
    }
    _;
  }

  // Grant an address or revoke the ability to call `spendFrom()`.
  // `admin` should do this for new versions of protocol contracts.
  function setAuthority(address authority, bool enabled) external onlyOwner {
    authorized[authority] = enabled;
  }

  /**
   * @notice Transfer ERC20 in from address; can only be called by authorized contracts
   * @param token     Token address
   * @param amount    Amount to withdraw
   */
  function transferERC20(IERC20 token, address from, address to, uint256 amount) external onlyAuthorized {
    SafeERC20.safeTransferFrom(token, from, to, amount);
  }

  /**
   * @notice Transfer ERC721 in from address; can only be called by authorized contracts
   * @param token     Token address
   * @param id       Token id to withdraw
   * @param from      Address to withdraw from
    * @param to Address to withdraw to
   */
  function transferERC721(IERC721 token, address from, address to, uint256 id) external virtual onlyAuthorized {
    token.safeTransferFrom(from, to, id);
  }

  /**
   * @notice Withdraw ERC1155 in from address; can only be called by authorized contracts
   * @param token     Token address
   * @param id     Token id to withdraw
   * @param amount       Amount to withdraw
   * @param from      Address to withdraw from
    * @param to Address to withdraw to
   */
  function transferERC1155(
    IERC1155 token,
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) external onlyAuthorized {
    token.safeTransferFrom(from, to, id, amount, "");
  }
}