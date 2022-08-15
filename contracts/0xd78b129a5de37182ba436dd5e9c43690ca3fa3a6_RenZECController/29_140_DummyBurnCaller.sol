// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
import { BadgerBridgeZeroController } from "../controllers/BadgerBridgeZeroController.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/SplitSignatureLib.sol";

contract DummyBurnCaller {
  constructor(address controller, address renzec) {
    IERC20(renzec).approve(controller, ~uint256(0) >> 2);
  }

  function callBurn(
    address controller,
    address from,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory signature,
    bytes memory destination
  ) public {
    (uint8 v, bytes32 r, bytes32 s) = SplitSignatureLib.splitSignature(signature);
    uint256 nonce = IERC2612Permit(asset).nonces(from);
    IERC2612Permit(asset).permit(from, address(this), nonce, deadline, true, v, r, s);
    address payable _controller = address(uint160(controller));
    BadgerBridgeZeroController(_controller).burnApproved(from, asset, amount, 1, destination);
  }
}