// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHegicStaking is IERC20 {    
    event Claim(address indexed acount, uint amount);
    event Profit(uint amount);

    function lockupPeriod() external view returns (uint256);
    function lastBoughtTimestamp(address) external view returns (uint256);

    function claimProfit() external returns (uint profit);
    function buy(uint amount) external;
    function sell(uint amount) external;
    function profitOf(address account) external view returns (uint);
}