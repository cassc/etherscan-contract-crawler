pragma solidity ^0.8.0;

import "../interfaces/IMarket.sol";

interface IMarketFactory {
    function getPlatformFee() external view returns (uint256);

    function getPlatformFeeReceiver() external view returns (address);

    function calFee(
        address pool,
        uint256 marketFee,
        uint256 amountPay
    ) external view returns (uint256 eventFeeAmount, uint256 platformFeeAmount);

    function calcSplit(address pool, uint256 amount)
        external
        view
        returns (uint256, uint256);
}