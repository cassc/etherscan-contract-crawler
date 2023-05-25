// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Context } from "@openzeppelin/contracts/access/Ownable.sol";
import { Delegatable, DelegatableCore } from "./Delegatable/Delegatable.sol";

interface IERC721Mintable {
  function mint(address to) external;

  function burn(uint256 tokenId) external;
}

contract DelegatableERC721Controller is AccessControl, Delegatable {
  address public erc721TokenAddress;
  bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

  constructor(address _erc721TokenAddress, address admin, address controller)
    Delegatable("DelegatableERC721Controller", "1")
  {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(CONTROLLER_ROLE, controller);
    erc721TokenAddress = _erc721TokenAddress;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function controllerMint(address account) external virtual {
    require(hasRole(CONTROLLER_ROLE, _msgSender()), "DelegatableERC721Controller:unauthorized");
    IERC721Mintable(erc721TokenAddress).mint(account);
  }

  function controllerBurn(uint256 tokenId) external virtual {
    require(hasRole(CONTROLLER_ROLE, _msgSender()), "DelegatableERC721Controller:unauthorized");
    IERC721Mintable(erc721TokenAddress).burn(tokenId);
  }

  function grantMinterRole(address _minter) external virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DelegatableERC721Controller:unauthorized");
    grantRole(CONTROLLER_ROLE, _minter);
  }

  function revokeMinter(address _minter) external virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DelegatableERC721Controller:unauthorized");
    revokeRole(CONTROLLER_ROLE, _minter);
  }

  function transferAdmin(address account) external {
    grantRole(DEFAULT_ADMIN_ROLE, account);
    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _msgSender()
    internal
    view
    virtual
    override(Context, DelegatableCore)
    returns (address sender)
  {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }
}