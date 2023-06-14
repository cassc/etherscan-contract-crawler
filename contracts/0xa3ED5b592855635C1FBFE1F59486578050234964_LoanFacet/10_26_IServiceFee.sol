// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface IServiceFee {
    function setServiceFee(
        address _target,
        address _nftAsset,
        uint16 _fee
    ) external;

    function clearServiceFee(address _target, address _nftAsset) external;

    function getServiceFeeRate(
        address _target,
        address _nftAsset
    ) external view returns (uint16);

   function getServiceFee(
        address _target,
        address _nftAsset,
        uint256 _borrowAmount
    ) external view returns (uint16 feeRate, uint256 fee);

    function collectServiceFee(
        address target,
        address nftAsset,
        address borrowAsset,
        uint256 borrowAmount,
        address feeReceiver,
        address compenstor
    ) external;
}