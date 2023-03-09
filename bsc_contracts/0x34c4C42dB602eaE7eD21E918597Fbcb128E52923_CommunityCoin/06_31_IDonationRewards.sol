// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./IHook.sol";
interface IDonationRewards is IHook {
    
    function bonus(address instance, address account, uint64 duration, uint256 amount) external;
    function transferHook(address operator, address from, address to, uint256 amount) external returns(bool);
    function claim() external;
    // methods above will be refactored 

    function onDonate(address token, address who, uint256 amount) external;
 
}