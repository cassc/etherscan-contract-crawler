// SPDX-License-Identifier: MIT

import { Ownable } from "oz410/access/Ownable.sol";
import { ZeroController } from "../controllers/ZeroController.sol";

/**
@title contract that is the simplest underwriter, just a proxy with an owner tag
@author raymondpulver
*/
contract TrivialUnderwriter is Ownable {
  address payable public immutable controller;

  constructor(address payable _controller) Ownable() {
    controller = _controller;
  }

  function bubble(bool success, bytes memory response) internal pure {
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
  ) public {
    require(msg.sender == owner(), "must be called by owner");
    ZeroController(controller).loan(to, asset, amount, nonce, module, data, userSignature);
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
  ) public {
    require(msg.sender == owner(), "must be called by owner");
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

  /**
  @notice handles any other call and forwards to the controller
  */
  fallback() external payable {
    require(msg.sender == owner(), "must be called by owner");
    (bool success, bytes memory response) = controller.call{ value: msg.value }(msg.data);
    bubble(success, response);
  }
}