// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NFTingSingleToken.sol";

contract NFTingSingleTokenFactory is Ownable {
    using SafeMath for uint256;

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
        if (
            bytes(_initBaseURI)[bytes(_initBaseURI).length.sub(1)] !=
            bytes1("/")
        ) revert NoTrailingSlash(_initBaseURI);

        NFTingSingleToken collection = new NFTingSingleToken(
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