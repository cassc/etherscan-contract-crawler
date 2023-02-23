// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for NETH
 */
interface INETH is IERC20 {
    /**
     * @notice mint nETHH
     * @param _amount mint amount
     * @param _account mint account
     */
    function whiteListMint(uint256 _amount, address _account) external;

    /**
     * @notice burn nETHH
     * @param _amount burn amount
     * @param _account burn account
     */
    function whiteListBurn(uint256 _amount, address _account) external;

    event LiquidStakingContractSet(address _OldLiquidStakingContractAddress, address _liquidStakingContractAddress);
}