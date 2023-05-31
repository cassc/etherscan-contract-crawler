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

import "../MinteebleDynamicCollection.sol";
import "../extensions/SimpleMultiWhitelistExtension.sol";

contract MinteebleDynamicCollection_SimpleMultiWhitelist is
    MinteebleDynamicCollection,
    SimpleMultiWhitelistExtension
{
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    )
        MinteebleDynamicCollection(
            _tokenName,
            _tokenSymbol,
            _maxSupply,
            _mintPrice
        )
    {}

    function whitelistMint(uint256 _groupId, bytes32[] calldata _merkleProof)
        public
        payable
        virtual
        canWhitelistMint(_groupId, _merkleProof)
        canMint(1)
    {
        _safeMint(_msgSender(), 1);
        totalMintedByAddress[_msgSender()] += 1;
        _consumeWhitelist(_groupId, msg.sender);
    }

    function createWhitelistGroup(
        uint256 _groupId,
        bytes32 _merkleRoot,
        uint256 _price
    ) public onlyOwner {
        _createWhitelistGroup(_groupId, _merkleRoot, _price);
    }

    function setWhitelistGroupEnabled(uint256 _groupId, bool _enabled)
        public
        onlyOwner
    {
        _setWhitelistGroupEnabled(_groupId, _enabled);
    }

    function setWhitelistMerkleRoot(uint256 _groupId, bytes32 _merkleRoot)
        public
        onlyOwner
    {
        _setWhitelistMerkleRoot(_groupId, _merkleRoot);
    }

    function setWhitelistPrice(uint256 _groupId, uint256 _price)
        public
        onlyOwner
    {
        _setWhitelistPrice(_groupId, _price);
    }

    function consumeWhitelist(uint256 _groupId, address _account)
        public
        onlyOwner
    {
        _consumeWhitelist(_groupId, _account);
    }
}