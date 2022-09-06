//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "../../Types.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../IDexRouter.sol";
import "../../BaseAccess.sol";

// @dev The ZrxRouter is used by settlement to execute orders through 0x
contract ZrxRouter is BaseAccess, IDexRouter {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    function initialize() public initializer {
      BaseAccess.initAccess();
    }

  // @dev Executes a call to 0x to make fill the order
  // @param order - contains the order details from the Smart Order Router
  // @param orderCallData - abi encoded swapTarget address and data from 0x API
  function fill(Types.Order calldata order, bytes calldata orderCallData) 
    external override returns (bool success, string memory failReason) {

      //call data contains the target address and data to pass to it to execute
      (address swapTarget, address allowanceTarget, bytes memory data) = abi.decode(orderCallData, (address,address,bytes));
      console.log("------------- ZRX ROUTER --------------");
      console.log("Going to swap target", swapTarget);
      console.log("Approving allowance for", allowanceTarget);
      console.log("Swapping input amount", order.input.amount);

      //Settlement transferred token input amount so we can swap
      uint256 balanceBefore = order.output.token.balanceOf(address(this));
    
      console.log("Balance of output token b4", balanceBefore);

      //for protocols that require zero-first approvals
      require(order.input.token.approve(allowanceTarget, 0));

      //make sure 0x target has approval to spend this contract's tokens
      require(order.input.token.approve(allowanceTarget, order.input.amount));

      //execute the swap
      console.log("Swapping with gasleft", gasleft());
      (bool _success,) = swapTarget.call{gas: gasleft()}(data);
      console.log("Gas after swap", gasleft());

      if(!_success) {
        console.log("Failed to swap");
        console.log("---- END ZRX ROUTER ----");
        return (false, "SWAP_CALL_FAILED");
      }

      //make sure we received tokens
      uint256 balanceAfter = order.output.token.balanceOf(address(this));
      console.log("Balance after", balanceAfter);
      uint256 diff = balanceAfter.sub(balanceBefore);
      console.log("Balance received", diff);
      console.log("Min required", order.output.amount);

      require(diff >= order.output.amount, "Insufficient output amount");
      //SafeERC should revert on this call if there's a problem
      order.output.token.safeTransfer(_msgSender(), diff);
      console.log("Transferred result to", _msgSender());
      console.log("---- END ZRX ROUTER ----");
      return (true, "");
  }

  // Payable fallback to allow this contract to receive protocol fee refunds.
  receive() external payable {}

}