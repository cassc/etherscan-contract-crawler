// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface INFTSalesFactory {
    function _doMintAndDistribute(uint256[] memory tokenIds, address[] memory addresses) external;

    function instanceToNFTContract(address instanceAddress) external view returns (address addr);

    function whitelistByNFTContract(address NFTContract) external view returns (address[] memory instances);
    
}