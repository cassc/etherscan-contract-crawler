// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WrapToken
interface IWrapToken is IERC20 {

    function originToken() external view returns(address);
    
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {depositFrom}. This is
     * zero by default.
     *
     * This value changes when {depositApprove} or {depositFrom} are called.
     */
    function depositAllowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards
     */
    function depositApprove(address spender, uint256 amount) external;
    function depositFrom(address from, address to, uint256 amount) external returns(uint256 actualAmount);
    function withdraw(address to, uint256 amount) external returns(uint256 actualAmount);
}