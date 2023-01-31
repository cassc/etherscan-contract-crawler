// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IServiceFee {
    function setServiceFee(
        address _target,
        address _sender,
        address _nftAsset,
        uint16 _fee
    ) external;

    function clearServiceFee(
        address _target,
        address _sender,
        address _nftAsset
    ) external;

    function getServiceFee(
        address _target,
        address _sender,
        address _nftAsset
    ) external view returns (uint16);
}