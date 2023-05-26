// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PunksV1Contract {

    // Events

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    // Read contract

    function name() external view returns (string memory);

    function punksOfferedForSale(uint id) external view returns (bool isForSale, uint punkIndex, address seller, uint minValue, address onlySellTo);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint8);

    function imageHash() external view returns (string memory);

    function nextPunkIndexToAssign() external view returns (uint);

    function punkIndexToAddress(uint id) external view returns (address);

    function standard() external view returns (string memory);

    function balanceOf(address) external view returns (uint);

    function symbol() external view returns (string memory);

    function numberOfPunksToReserve() external view returns (uint);

    function numberOfPunksReserved() external view returns (uint);

    function punksRemainingToAssign() external view returns (uint);

    function pendingWithdrawals(address) external view returns (uint);

    // Write contract

    function reservePunksForOwner(uint maxForThisRun) external;

    function withdraw() external;

    function buyPunk(uint id) external payable;

    function transferPunk(address to, uint id) external;

    function offerPunkForSaleToAddress(uint id, uint minSalePriceInWei, address to) external;

    function offerPunkForSale(uint id, uint minSalePriceInWei) external;

    function getPunk(uint id) external;

    function punkNoLongerForSale(uint id) external;

}