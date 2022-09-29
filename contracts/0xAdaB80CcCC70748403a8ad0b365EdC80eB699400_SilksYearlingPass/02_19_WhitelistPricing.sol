// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhitelistPricing is Ownable {
    struct Whitelist {
        bytes32 merkleRoot;
        uint price;
        bool paused;
        uint maxPerTx;
        uint maxPerWallet;
        bool valid;
    }
    
    mapping(uint => Whitelist) internal whitelists;
    
    function getWhitelist(
        uint _id
    )
    public
    view
    returns (
        uint price,
        bool paused,
        uint maxPerTx,
        uint maxPerWallet,
        bool valid
    )
    {
        return (
        whitelists[_id].price,
        whitelists[_id].paused,
        whitelists[_id].maxPerTx,
        whitelists[_id].maxPerWallet,
        whitelists[_id].valid
        );
    }
    
    function isWhitelisted(
        uint _id,
        address _address,
        bytes32[] calldata _merkleProof
    )
    public
    view
    returns (bool)
    {
        if (whitelists[_id].valid && whitelists[_id].merkleRoot.length > 0) {
            bytes32 node = keccak256(abi.encodePacked(_address));
            return MerkleProof.verify(
                _merkleProof,
                whitelists[_id].merkleRoot,
                node
            );
        }
        return false;
    }
    
    function setWhitelist(
        uint _id,
        bytes32 _merkleRoot,
        uint _price,
        bool _paused,
        uint _maxPerTx,
        uint _maxPerWallet
    )
    external
    onlyOwner
    {
        whitelists[_id] = Whitelist(
            _merkleRoot,
            _price,
            _paused,
            _maxPerTx,
            _maxPerWallet,
            true
        );
    }
}