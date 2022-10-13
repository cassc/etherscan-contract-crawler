pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { ReturnFundsData } from "../../core/types/Common.sol";
import { RETURN_FUNDS_ACTION, ETH } from "../../core/constants/Common.sol";
import { DSProxy } from "../../libs/DS/DSProxy.sol";

contract ReturnFunds is Executable {
  using SafeERC20 for IERC20;

  function execute(bytes calldata data, uint8[] memory) external payable override {
    ReturnFundsData memory returnData = abi.decode(data, (ReturnFundsData));
    address owner = DSProxy(payable(address(this))).owner();
    uint256 amount;

    if (returnData.asset == ETH) {
      amount = address(this).balance;
      payable(owner).transfer(amount);
    } else {
      amount = IERC20(returnData.asset).balanceOf(address(this));
      IERC20(returnData.asset).safeTransfer(owner, amount);
    }

    emit Action(RETURN_FUNDS_ACTION, bytes32(abi.encodePacked(amount, returnData.asset)));
  }
}