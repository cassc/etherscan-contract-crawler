// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../compound/ICompound.sol";

interface ISafeBox is IERC20Metadata {
    event Claim(address user, uint256 amount);

    function cToken() external view returns (CToken);

    // Not available for safeBoxEth
    function uToken() external view returns (IERC20);

    // only available in safeBoxEth
    function weth() external view returns (IERC20);

    function deposit(uint256 amount) external;

    // Overload for safeBoxEth
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function claim(uint256 totalAmount, bytes32[] memory proof) external;

    function claimAndWithdraw(uint256 totalAmount, bytes32[] memory proof, uint256 withdrawAmount) external;
}