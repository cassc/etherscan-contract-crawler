// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import { Swap } from "../modules/Swap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapRelease {
  address constant swap = 0x129F31e121B0A8C05bf10347F34976238F1f15DC;
  address constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
  address constant governance = 0x12fBc372dc2f433392CC6caB29CFBcD5082EF494;
  address constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

  fallback() external {
    IERC20(wbtc).transfer(swap, IERC20(wbtc).balanceOf(address(this)));
    Swap(swap).receiveLoan(address(0), address(0), IERC20(wbtc).balanceOf(swap), 1, hex"");
    Swap(swap).repayLoan(governance, address(0), IERC20(usdc).balanceOf(swap), uint256(1), hex"");
  }
}