// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with Snacks/BtcSnacks/EthSnacks contracts.
*/
interface ISnacksBase {
    function mintWithBuyTokenAmount(uint256 buyTokenAmount) external returns (uint256);
    function mintWithPayTokenAmount(uint256 payTokenAmount) external returns (uint256);
    function isExcludedHolder(address account) external view returns (bool);
    function redeem(uint256 buyTokenAmount) external returns (uint256);
    function adjustmentFactor() external view returns (uint256);
    function sufficientBuyTokenAmountOnMint(
        uint256 buyTokenAmount
    ) 
        external 
        view
        returns (bool);
    function sufficientPayTokenAmountOnMint(
        uint256 payTokenAmount
    )
        external
        view
        returns (bool);
    function sufficientBuyTokenAmountOnRedeem(
        uint256 buyTokenAmount
    )
        external
        view
        returns (bool);
}