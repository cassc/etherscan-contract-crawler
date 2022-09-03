// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

interface ISudoGate { 
    function pools(address, uint256) external view returns (address);
    function knownPool(address) external view returns (bool);
    function buyQuote(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyQuoteWithFees(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyFromPool(address pool) external payable returns (uint256 tokenID);
    function registerPool(address sudoswapPool) external returns (bool);

}