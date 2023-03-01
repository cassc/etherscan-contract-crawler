// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INonfungiblePositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function balanceOf(address owner) external view returns (uint256);
    
    function collect(CollectParams memory params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function ownerOf(uint256 tokenId) external view returns (address);
    
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}