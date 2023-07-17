// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface IStargateEthVault {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;

    function approve(address guy, uint wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) external returns (bool);
}