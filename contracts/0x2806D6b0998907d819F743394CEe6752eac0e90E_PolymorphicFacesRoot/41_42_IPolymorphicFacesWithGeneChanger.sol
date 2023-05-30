// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IPolymorphicFacesWithGeneChanger {
    function morphGene(uint256 tokenId, uint256 genePosition) external payable;

    function randomizeGenome(uint256 tokenId) external payable;

    function priceForGenomeChange(uint256 tokenId)
        external
        view
        returns (uint256 price);

    function changeBaseGenomeChangePrice(uint256 newGenomeChangePrice) external;

    function changeRandomizeGenomePrice(uint256 newRandomizeGenomePrice)
        external;

    function whitelistBridgeAddress(address bridgeAddress, bool status)
        external;

    function genomeChanges(uint256 tokenId)
        external
        view
        returns (uint256 genomeChnages);
}