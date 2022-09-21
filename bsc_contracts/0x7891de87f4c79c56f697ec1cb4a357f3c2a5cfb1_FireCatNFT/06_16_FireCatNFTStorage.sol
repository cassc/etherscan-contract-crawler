// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract FireCatNFTStorage {

    /**
     * @notice Main workflow address for Fire Cat Finance.
     */
    address public fireCatProxy;

    /**
     * @notice NFT's level Upgrade Proxy Contract for Fire Cat NFT.
     */
    address public upgradeProxy;

    /**
     * @notice NFT's level Upgrade Condition Storage Contract for Fire Cat NFT.
     */
    address public upgradeStorage;
    
    /**
     * @dev To set the base uri of where metadata presides.
     */
    string public baseURI;

    /**
     * @notice Total number of tokens.
     */
    uint256 public currentTokenId;

}