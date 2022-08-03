// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ISoulink.sol";

interface ISoulinkMinter {
    event SetMintPrice(uint96 mintPrice);
    event SetFeeTo(address feeTo);
    event SetLimit(uint96 limit);
    event SetDiscountDB(address db);

    function soulink() external view returns (ISoulink);

    function mintPrice() external view returns (uint96);

    function feeTo() external view returns (address);

    function limit() external view returns (uint96);

    function discountDB() external view returns (address);

    function mint(bool discount, bytes calldata data) external payable returns (uint256 id);
}