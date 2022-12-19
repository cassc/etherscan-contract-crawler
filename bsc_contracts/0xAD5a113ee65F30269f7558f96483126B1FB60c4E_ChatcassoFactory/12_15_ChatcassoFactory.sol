// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ChatcassoNFT.sol";

/**
 * @title Chatcasso Factory
 * @dev A NFT factory that deploys new NFT contracts using the minimal proxy pattern (EIP-1167)
 */
contract ChatcassoFactory is Ownable {
    error ChatcassoFactory__InvalidName();
    error ChatcassoFactory__InvalidSymbol();
    error ChatcassoFactory__DescriptionTooLong();
    error ChatcassoFactory__InvalidMaxSupply();
    error ChatcassoFactory__InvalidImageCID();

    address public nftImplementation;
    address[] public collections;

    event CreateCollection(address indexed nftAddress, string name, string symbol);

    constructor(address implementation) {
        nftImplementation = implementation;
    }

    /** @dev
     *  Use "EIP-1167: Minimal Proxy Contract" in order to save gas cost for each token deployment
     *  REF: https://github.com/optionality/clone-factory
     */
    function _createClone(address target) private returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata description,
        uint32 maxSupply,
        uint184 mintingCost,
        string calldata imageCID
    ) external returns (address) {
        if (bytes(name).length == 0) revert ChatcassoFactory__InvalidName();
        if (bytes(symbol).length == 0) revert ChatcassoFactory__InvalidSymbol();
        if (bytes(description).length > 1000) revert ChatcassoFactory__DescriptionTooLong(); // ~900 gas per character
        if (maxSupply == 0) revert ChatcassoFactory__InvalidMaxSupply();
        if (bytes(imageCID).length == 0) revert ChatcassoFactory__InvalidImageCID();

        address nftAddress = _createClone(nftImplementation);
        ChatcassoNFT newNFT = ChatcassoNFT(nftAddress);
        newNFT.init(msg.sender, name, symbol, description, maxSupply, mintingCost, imageCID);

        collections.push(nftAddress);

        emit CreateCollection(nftAddress, name, symbol);

        return nftAddress;
    }

    // MARK: - Admin functions

    // @dev Admin functions to add a NFT collection manually for migration
    function addCollection(address nftAddress) external onlyOwner {
        collections.push(nftAddress);
    }

    // @dev If necessary, upgrade the NFT implementation. This will not affect existing collections
    function updateImplementation(address newImplementation) external onlyOwner {
        nftImplementation = newImplementation;
    }

    // MARK: - Utility functions

    function collectionCount() external view returns (uint256) {
        return collections.length;
    }
}