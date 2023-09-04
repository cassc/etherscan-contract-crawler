// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 @notice Issues wrapped DAI tokens that can only be transferred to holders that maintain
 compliance with the configured policy.
 */

interface IKycERC20 is IERC20 {
    
    function depositFor(address account, uint256 amount) external returns (bool);
    
    function withdrawTo(address account, uint256 amount) external returns (bool);
}