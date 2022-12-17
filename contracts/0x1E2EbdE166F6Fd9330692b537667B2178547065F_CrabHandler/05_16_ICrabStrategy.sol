// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICrabStrategy is IERC20Metadata {
    /**
     * @notice flash withdraw from strategy, providing strategy tokens, buying wSqueeth, burning and receiving ETH
     * @dev this function will execute a flash swap where it receives wSqueeth, burns, withdraws ETH and then repays the flash swap with ETH
     * @param _crabAmount strategy token amount to burn
     * @param _maxEthToPay maximum ETH to pay to buy back the wSqueeth debt
     * @param _poolFee Uniswap pool fee
     */
    function flashWithdraw(uint256 _crabAmount, uint256 _maxEthToPay, uint24 _poolFee) external;
}