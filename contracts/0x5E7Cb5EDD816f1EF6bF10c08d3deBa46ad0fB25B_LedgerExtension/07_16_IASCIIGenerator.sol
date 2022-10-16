// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IASCIIGenerator {

    /** 
     * @notice Generates full metadata
     */
    function generateMetadata(address _nftContract, uint256 _tokenId, uint256 _lastUpdatedBlock) external view returns (string memory);

}