// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Sale.sol";

interface IBasicSale {
    function getCurrentSale()
        external
        view
        returns (
            uint8,
            SaleType,
            uint256,
            uint256
        );

    function setCurrentSale(Sale calldata sale) external;

    function withdraw() external;

    function setWithdrawAddress(address payable value) external;

    function setMaxSupply(uint256 value) external;

    function pause() external;

    function unpause() external;
}