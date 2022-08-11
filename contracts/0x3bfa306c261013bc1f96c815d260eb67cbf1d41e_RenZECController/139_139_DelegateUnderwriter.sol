// SPDX-License-Identifier: MIT

import { Ownable } from "oz410/access/Ownable.sol";
import { ZeroController } from "../controllers/ZeroController.sol";

/**
@title contract that is the simplest underwriter, just a proxy with an owner tag
*/
contract DelegateUnderwriter is Ownable {
  address payable public immutable controller;
  mapping(address => bool) private authorized;

  modifier onlyAuthorized() {
    require(authorized[msg.sender], "!authorized");
    _;
  }

  function addAuthority(address _authority) public onlyOwner {
    authorized[_authority] = true;
  }

  function removeAuthority(address _authority) public onlyOwner {
    authorized[_authority] = false;
  }

  function _initializeAuthorities(address[] memory keepers) internal {
    for (uint256 i = 0; i < keepers.length; i++) {
      authorized[keepers[i]] = true;
    }
  }

  constructor(
    address owner,
    address payable _controller,
    address[] memory keepers
  ) Ownable() {
    controller = _controller;
    _initializeAuthorities(keepers);
    transferOwnership(owner);
  }

  function bubble(bool success, bytes memory response) internal {
    assembly {
      if iszero(success) {
        revert(add(0x20, response), mload(response))
      }
      return(add(0x20, response), mload(response))
    }
  }

  /**
    @notice proxy a regular call to an arbitrary contract
    @param target the to address of the transaction
    @param data the calldata for the transaction
    */
  function proxy(address payable target, bytes memory data) public payable onlyOwner {
    (bool success, bytes memory response) = target.call{ value: msg.value }(data);
    bubble(success, response);
  }

  function loan(
    address to,
    address asset,
    uint256 amount,
    uint256 nonce,
    address module,
    bytes memory data,
    bytes memory userSignature
  ) public onlyAuthorized {
    ZeroController(controller).loan(to, asset, amount, nonce, module, data, userSignature);
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory destination,
    bytes memory signature
  ) public onlyAuthorized {
    ZeroController(controller).burn(to, asset, amount, deadline, destination, signature);
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public onlyAuthorized {
    ZeroController(controller).repay(
      underwriter,
      to,
      asset,
      amount,
      actualAmount,
      nonce,
      module,
      nHash,
      data,
      signature
    );
  }

  function meta(
    address from,
    address asset,
    address module,
    uint256 nonce,
    bytes memory data,
    bytes memory userSignature
  ) public onlyAuthorized {
    ZeroController(controller).meta(from, asset, module, nonce, data, userSignature);
  }

  /**
  @notice handles any other call and forwards to the controller
  */
  fallback() external payable {
    require(msg.sender == owner(), "must be called by owner");
    (bool success, bytes memory response) = controller.call{ value: msg.value }(msg.data);
    bubble(success, response);
  }
}