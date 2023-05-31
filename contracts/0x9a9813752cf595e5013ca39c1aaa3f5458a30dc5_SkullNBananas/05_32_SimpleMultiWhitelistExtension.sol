// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ISimpleMultiWhitelistExtension {}

abstract contract SimpleMultiWhitelistExtension is
    ISimpleMultiWhitelistExtension
{
    struct WhitelistGroup {
        bool created;
        bool enabled;
        bytes32 merkleRoot;
        uint256 price;
        mapping(address => bool) used;
    }

    mapping(uint256 => WhitelistGroup) public whitelistGroups;

    modifier canWhitelistMint(
        uint256 _groupId,
        bytes32[] calldata _merkleProof
    ) {
        require(
            whitelistGroups[_groupId].enabled,
            "The whitelist sale is not enabled for this group!"
        );

        require(
            !whitelistGroups[_groupId].used[msg.sender],
            "Exceeded maximum total amount per address!"
        );

        require(
            msg.value >= whitelistGroups[_groupId].price,
            "Insufficient funds!"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(
                _merkleProof,
                whitelistGroups[_groupId].merkleRoot,
                leaf
            ),
            "Invalid proof!"
        );
        _;
    }

    modifier isWhitelistGroupValid(uint256 _groupId) {
        require(whitelistGroups[_groupId].created, "Invalid group");
        _;
    }

    function whitelistGroupExists(uint256 _groupId) public view returns (bool) {
        return whitelistGroups[_groupId].created;
    }

    function getWhitelistPrice(uint256 _groupId) public view returns (uint256) {
        return whitelistGroups[_groupId].price;
    }

    function getWhitelistMerkleRoot(uint256 _groupId)
        public
        view
        returns (bytes32)
    {
        return whitelistGroups[_groupId].merkleRoot;
    }

    function isWhitelistUsed(uint256 _groupId, address _account)
        public
        view
        returns (bool)
    {
        return whitelistGroups[_groupId].used[_account];
    }

    function _createWhitelistGroup(
        uint256 _groupId,
        bytes32 _merkleRoot,
        uint256 _price
    ) internal {
        require(!whitelistGroups[_groupId].created, "Group already exists");

        whitelistGroups[_groupId].enabled = false;
        whitelistGroups[_groupId].created = true;
        whitelistGroups[_groupId].merkleRoot = _merkleRoot;
        whitelistGroups[_groupId].price = _price;
    }

    function _setWhitelistGroupEnabled(uint256 _groupId, bool _enabled)
        internal
        isWhitelistGroupValid(_groupId)
    {
        whitelistGroups[_groupId].enabled = _enabled;
    }

    function _setWhitelistMerkleRoot(uint256 _groupId, bytes32 _merkleRoot)
        internal
        isWhitelistGroupValid(_groupId)
    {
        whitelistGroups[_groupId].merkleRoot = _merkleRoot;
    }

    function _setWhitelistPrice(uint256 _groupId, uint256 _price)
        internal
        isWhitelistGroupValid(_groupId)
    {
        whitelistGroups[_groupId].price = _price;
    }

    function _consumeWhitelist(uint256 _groupId, address _account)
        internal
        isWhitelistGroupValid(_groupId)
    {
        whitelistGroups[_groupId].used[_account] = true;
    }
}