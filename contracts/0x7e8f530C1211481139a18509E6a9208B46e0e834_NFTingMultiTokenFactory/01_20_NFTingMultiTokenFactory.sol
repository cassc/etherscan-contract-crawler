// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./NFTingMultiToken.sol";

contract NFTingMultiTokenFactory is Ownable {
    address[] private collections;
    mapping(address => bool) public isRegisteredCollection;

    event CollectionAdded(address _addr);

    INFTingConfig config;

    function setConfig(address newConfig) external onlyOwner {
        if (newConfig == address(0)) {
            revert ZeroAddress();
        }
        config = INFTingConfig(newConfig);
    }

    function deployCollection(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) external {
        if (bytes(_initBaseURI)[bytes(_initBaseURI).length - 1] != bytes1("/"))
            revert NoTrailingSlash(_initBaseURI);

        NFTingMultiToken collection = new NFTingMultiToken(
            _name,
            _symbol,
            _initBaseURI,
            address(config)
        );
        collection.transferOwnership(_msgSender());
        address addr = address(collection);
        isRegisteredCollection[addr] = true;
        collections.push(addr);

        emit CollectionAdded(addr);
    }

    function getAllCollections() external view returns (address[] memory) {
        return collections;
    }
}