// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IThePass {
    function burn(
        uint256 passTypeId,
        address account,
        uint256 amount
    ) external;

    event PassOptionCreated(
        uint256 indexed passSaleId,
        uint256 indexed passTypeId,
        uint256 indexed price
    );

    event PassOptionUpdated(
        uint256 indexed passSaleId,
        uint256 indexed passTypeId,
        uint256 indexed price
    );

    event SaleStarted(
        uint256 indexed passSaleId,
        uint256 maxPerMint,
        bool presale
    );

    event SaleStopped(uint256 indexed passSaleId);
}