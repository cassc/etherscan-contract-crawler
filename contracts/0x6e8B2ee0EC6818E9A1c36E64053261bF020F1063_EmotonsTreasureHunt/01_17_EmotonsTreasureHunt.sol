// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Emotons.sol";

contract EmotonsTreasureHunt is Ownable, ERC1155Holder {
    Emotons public _emotons;
    bytes32 public _secretLockKey;
    uint256 public _tokenId;

    constructor(
        Emotons emotons,
        bytes32 secretLockKey,
        uint256 tokenId
    ) {
        _emotons = emotons;
        _secretLockKey = secretLockKey;
        _tokenId = tokenId;
    }

    function claimTreasure(string calldata ipfsCid) public {
        require(
            _secretLockKey == keccak256(abi.encodePacked(ipfsCid)),
            "Wrong key"
        );
        _emotons.setSecretLockKey(_secretLockKey, _tokenId);
        _secretLockKey = 0;
        _emotons.mintSecret(ipfsCid);
        _emotons.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
    }

    function emotonsTransferOwnership(address newOwner) public onlyOwner {
        _emotons.transferOwnership(newOwner);
    }
}