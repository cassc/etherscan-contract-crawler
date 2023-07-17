// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface INmbBreeder {
    function getChildOf(
        address parentTokenContractAddress,
        uint256 tokenId
    ) external view returns (uint256);

    
    function getParentsOf(
        uint256 tokenId
    ) external view returns (address, uint256, address, uint256);

    function getHasMated(
        address parentTokenContractAddress, 
        uint256[] memory tokenIds
    ) external view returns (bool[] memory);

}