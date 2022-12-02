// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Sweeper
 * @author Railgun Contributors
 * @notice Sweeps funds into another address
 */
contract Sweeper {
  address public immutable receiver;

  constructor(address _receiver) {
    receiver = _receiver;
  }

  /**
   * @notice Transfers ETH to receiver address
   */
  function transferETH() external {
    // solhint-disable-next-line avoid-low-level-calls
    receiver.call{ value: address(this).balance }("");
  }

  /**
   * @notice Transfers ERC20 to receiver address
   * @param _token - ERC20 token address to transfer
   */
  function transferERC20(IERC20 _token) external {
    _token.transfer(receiver, _token.balanceOf(address(this)));
  }
}