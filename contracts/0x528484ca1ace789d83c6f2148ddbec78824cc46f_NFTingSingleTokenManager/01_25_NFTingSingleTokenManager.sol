// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./utilities/NFTingBase.sol";
import "./NFTingSingleToken.sol";

contract NFTingSingleTokenManager is NFTingBase {
    using SafeMath for uint256;

    address[] private collections;
    mapping(address => bool) public isRegisteredCollection;

    event CollectionAdded(address _addr);

    function deployCollection(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) external {
        if (bytes(_initBaseURI)[bytes(_initBaseURI).length.sub(1)] != bytes1("/"))
            revert NoTrailingSlash(_initBaseURI);

        NFTingSingleToken collection = new NFTingSingleToken(
            _name,
            _symbol,
            _initBaseURI
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