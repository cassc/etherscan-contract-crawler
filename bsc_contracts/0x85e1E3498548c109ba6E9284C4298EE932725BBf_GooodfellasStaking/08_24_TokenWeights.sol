// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Uint16Array.sol";

/** 
 * @title Contract to track uint16 weights per tokenId
 *
 * @dev TokenIds are expected to be in [1..maxSupply]. 
 * To work around block gas limit, {addWeight} can be used to feed the weights incrementally.
 */
contract TokenWeights is Ownable {
    using Uint16Array for bytes;

    mapping(address => bytes) private weights;

    function addWeights(address _collection, bytes calldata _weights) external onlyOwner {
        weights[_collection].append(_weights);
    }
    
    function weightOfToken(address _collection, uint256 _tokenId) external view returns (uint256) {
        return _weightOfToken(_collection, _tokenId);
    }

    function _weightOfToken(address _collection, uint256 _tokenId) internal view returns (uint256) {
        return weights[_collection].at(_tokenId);
    }
}