// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IDoomsdaySettlersDisasters {
    function currentDisaster() external view returns (
        int64[2] memory _coordinates,
        int64 _radius,
        uint8 _type,
        bytes5 _disasterId
    );
    function recordDisaster() external;
}