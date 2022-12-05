// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/* @title ERC721ASnapshotable
 * @author minimizer <[email protected]>; https://minimizer.art/
 * 
 * This contract extends the ERC721AQueryable contract and adds snapshoting capability:
 * 
 * - The original owner of a given token is always remembered, in a gas efficient way by only
 *   storing the original owner at the time the token is transfered to the second owner.
 * 
 * - _takeSnapshot() creates a new snapshot (starting at 1) and stores the corresponding time.
 * 
 * - Any transfers after any snapshots have been taken perform a similar recording of ownership
 *   as the original owner. As a result, _snapshotTokenOwnershipOf(snapshotId, tokenId) will
 *   always return which address held the given token as of the time of the given snapshot.
 * 
 * 
 * Not implemented:
 * 
 * - balanceOf() or tokensOfOwner() for a given snapshot, as this would require additional gas
 *   for storage upon each transfer.
 * 
 * - Exposing whether token is burned, as not required for Infinite Scribble.
*/

contract ERC721ASnapshotable is ERC721AQueryable {
    
    struct SnapshotInfo {
        uint timestamp;
        uint totalMinted;
    }

    mapping(uint => SnapshotInfo) private _snapshots;
    uint private _latestSnapshotNumber = 0;
    
    mapping(uint => mapping(uint => TokenOwnership)) private _snapshotTokenOwnerships;
    
    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}
    
    modifier validSnapshot(uint snapshotNumber) {
        require(snapshotNumber > 0 && snapshotNumber <= _latestSnapshotNumber, 'Invalid snapshot');
        _;
    }
    
    function _latestSnapshot() internal view returns (uint) {
        return _latestSnapshotNumber;
    }
    
    function _takeSnapshot() internal {
        _latestSnapshotNumber+=1;
        _snapshots[_latestSnapshotNumber] = SnapshotInfo(block.timestamp, _totalMinted());
    }
    
    function _snapshotInfo(uint snapshotNumber) internal view validSnapshot(snapshotNumber) returns (SnapshotInfo memory) {
        return _snapshots[snapshotNumber];
    }
    
    function _originalTokenOwnershipOf(uint tokenId) internal view returns (TokenOwnership memory) {
        require(tokenId < _totalMinted(), 'Invalid tokenId');
        return _retrieveSnapshotTokenOwnershipOf(0, tokenId);
    }
    
    function _snapshotTokenOwnershipOf(uint snapshotNumber, uint tokenId) internal view validSnapshot(snapshotNumber) returns (TokenOwnership memory) {
        require(tokenId < _snapshots[snapshotNumber].totalMinted, 'Invalid tokenId for snapshot');
        return _retrieveSnapshotTokenOwnershipOf(snapshotNumber, tokenId);
    }
    
    function _retrieveSnapshotTokenOwnershipOf(uint snapshotNumber, uint tokenId) private view returns (TokenOwnership memory) {
        for(uint i=snapshotNumber;i<=_latestSnapshotNumber;i++) {
            if(_snapshotTokenOwnerships[i][tokenId].addr != address(0) || _snapshotTokenOwnerships[i][tokenId].burned) {
                return _snapshotTokenOwnerships[i][tokenId];
            }
        }
        if(_ownershipAt(tokenId).burned) {
            return _ownershipAt(tokenId);
        }
        return _ownershipOf(tokenId);
    }
    
    function _beforeTokenTransfers(address from, address /*to unused*/, uint tokenId, uint /*quantity always 1 for non-mint operations*/) internal virtual override {
        if(from != address(0)) {
            if(_snapshotTokenOwnerships[_latestSnapshotNumber][tokenId].addr == address(0)) {
                _snapshotTokenOwnerships[_latestSnapshotNumber][tokenId] = _ownershipOf(tokenId);
            }
        }
    }
}