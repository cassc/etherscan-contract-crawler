/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Easy Snapshotting of ERC721 Owners 

// Author: 0xInuarashi
// https://twitter.com/0xInuarashi || 0xInuarashi#1234

// Product of CypherLabz
// https://twitter.com/CypherLabz

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract ownerOfSnapshot {
    /** @dev Explanation: 
     *  _tryOwnerOf is a try-catch method of ownerOf that returns address(0) on failure
     */
    function _tryOwnerOf(address contract_, uint256 tokenId_) internal view
    returns (address) {
        address _owner;
        try IERC721(contract_).ownerOf(tokenId_) returns (address owner_) {
            _owner = owner_;
        }
        catch {
            _owner = address(0);
        }
        return _owner;
    }

    /** @dev Explanation:
     *  snapshotOwnerOf will return an array of all the addresses of owners of the 
     *  tokens queried
     */
    function snapshotOwnerOf(address contract_, uint256[] calldata tokenIds_)
    external view returns (address[] memory) {
        uint256 l = tokenIds_.length;
        address[] memory _addresses = new address[] (l);
        uint256 i; unchecked { do {
            _addresses[i] = _tryOwnerOf(contract_, tokenIds_[i]);
        } while (++i < l); }
        return _addresses;
    }

    /** @dev Explanation:
     *  snapshotTokensAreMinted will return a bool array of the minted state of
     *  all tokens queried
     */
    function snapshotTokensAreMinted(address contract_, uint256[] calldata tokenIds_)
    external view returns (bool[] memory) {
        uint256 l = tokenIds_.length;
        bool[] memory _tokensAreMinted = new bool[] (l);
        uint256 i; unchecked { do {
            _tokensAreMinted[i] = _tryOwnerOf(contract_, tokenIds_[i]) != address(0);
        } while (++i < l); }
        return _tokensAreMinted;
    }
}