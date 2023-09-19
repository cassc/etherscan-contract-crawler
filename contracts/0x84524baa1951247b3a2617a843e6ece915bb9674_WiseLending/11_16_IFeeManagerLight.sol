// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

interface IFeeManagerLight {
    function addPoolTokenAddress(
        address _poolToken
    )
        external;
}