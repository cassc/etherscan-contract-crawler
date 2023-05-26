// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


interface ISupplyManager {
    function supply() external view returns (uint16);
    function supplyUsed() external view returns (uint16);
    function reservedSupply() external view returns (uint16);
    function reservedSupplyUsed() external view returns (uint16);
    function initializeSupply () external;
    function mintFromPublicSupply( address minter, uint16 volume, uint256 amountSent, uint256 currentPrice, bool canMintFree ) external returns ( uint256 totalPrice, int256 refundAmount);
    function mintFromReservedSupply(address minter, uint256 volume) external;
    function tokenBurnt(uint256 tokenId ) external;
    function supplyMintedToday() external view returns (uint16);
    function resetSupplyPerDay() external;
}