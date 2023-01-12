// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IExchange {

    function buyFee() external view returns (uint256);

    function buyFeeDenominator() external view returns (uint256);

    function redeemFee() external view returns (uint256);

    function redeemFeeDenominator() external view returns (uint256);

    function balance() external view returns (uint256);

    /**
     * @param _asset Asset to spend
     * @param _amount Amount of asset to spend
     * @return Amount of minted USD+ to caller
     */
    function buy(address _asset, uint256 _amount) external returns (uint256);

    /**
     * @param _asset Asset to redeem
     * @param _amount Amount of USD+ to burn
     * @return Amount of asset unstacked and transferred to caller
     */
    function redeem(address _asset, uint256 _amount) external returns (uint256);

    function payout() external;

}