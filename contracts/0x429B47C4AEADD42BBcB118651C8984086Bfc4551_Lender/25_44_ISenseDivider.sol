// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface ISenseDivider {
    function redeem(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function pt(address, uint256) external view returns (address);

    // only used by integration tests
    function settleSeries(address, uint256) external;

    function adapterAddresses(uint256) external view returns (address);
}