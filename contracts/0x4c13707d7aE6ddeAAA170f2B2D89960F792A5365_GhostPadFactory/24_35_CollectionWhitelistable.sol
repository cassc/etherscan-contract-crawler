// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../GhostCollectionWhitelist.sol';
import '../../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol';

abstract contract CollectionWhitelistable is Ownable {
    address private _collectionWhitelist;
    event UpdateCollectionWhitelist(address indexed _address);

    modifier onlyCollectionWhitelist() {
        require(isCollectionWhitelist(msg.sender), 'CollectionWhitelistable : whitelist not contains msg.sender');
        _;
    }

    function isCollectionWhitelist(address _user) public view returns (bool) {
        return
            _collectionWhitelist == address(0) ||
            GhostCollectionWhitelist(_collectionWhitelist).isCollectionHolder(_user);
    }

    /**
     * @param _newCollectionWhitelist: new whitelist contract address
     */
    function _updateCollectionWhitelist(address _newCollectionWhitelist) internal {
        _collectionWhitelist = _newCollectionWhitelist;
        emit UpdateCollectionWhitelist(_newCollectionWhitelist);
    }

    function updateCollectionWhitelist(address _newCollectionWhitelist) external onlyOwner {
        _updateCollectionWhitelist(_newCollectionWhitelist);
    }
}