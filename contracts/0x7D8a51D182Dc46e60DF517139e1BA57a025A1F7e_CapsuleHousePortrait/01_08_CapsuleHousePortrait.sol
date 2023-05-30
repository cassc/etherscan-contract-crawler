// SPDX-License-Identifier: MIT
// Author: Eric Gao (@itsoksami, https://github.com/Ericxgao)

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICapsuleHouseElixir.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CapsuleHousePortrait is Ownable {
    using ECDSA for bytes32;

    mapping(uint256 => bool) public unlockedSwappableBackgrounds;
    mapping(uint256 => bool) public unlockedAnimated;

    IERC721 public capsules;
    IERC721 public zodiacs;
    ICapsuleHouseElixir public elixir;

    string public animatedElixirZodiacPrefix = "Animated Elixir Zodiac Verification:";
    string public animatedElixirPrefix = "Animated Elixir Verification:";
    string public swapElixirPrefix = "Swap Elixir Verification:";

    constructor(address elixirAddress, address capsulesAddress, address zodiacsAddress) {
        elixir = ICapsuleHouseElixir(elixirAddress);
        capsules = IERC721(capsulesAddress);
        zodiacs = IERC721(zodiacsAddress);
    }

    function bulkTransfer(uint256[] calldata tokenIds) internal {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            zodiacs.transferFrom(_msgSender(), address(this), tokenIds[i]);
        }
    }

    function _hash(string memory prefix, address _address, uint256[] calldata zodiacIds) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(prefix, _address, zodiacIds));
    }

    function _verify(bytes32 hash, bytes calldata signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes calldata signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function unlockSwappableBackgroundsWithElixir(uint16 tokenId) external {
        require(capsules.ownerOf(tokenId) == msg.sender, "You don't own this Capsule.");
        require(!unlockedSwappableBackgrounds[tokenId], "Already unlocked.");

        unlockedSwappableBackgrounds[tokenId] = true;

        elixir.burn(1, msg.sender);
    }

    function unlockAnimatedWithElixir(uint16 tokenId) external {
        require(capsules.ownerOf(tokenId) == msg.sender, "You don't own this Capsule.");
        require(!unlockedAnimated[tokenId], "Already unlocked.");

        unlockedAnimated[tokenId] = true;

        elixir.burn(2, msg.sender);
    }

    // Signature needed to validate here as we do our Zodiac type checking on server.
    // We could use a bunch of Merkle trees too but seems pretty inefficient, especially if we're going to have a signature based minting mechanism anyways.
    function unlockAnimatedWithZodiacs(bytes32 hash, bytes calldata signature, uint256[] calldata zodiacIds, uint256 tokenId) external {
        require(_verify(hash, signature), "Signature invalid.");
        require(_hash(animatedElixirZodiacPrefix, msg.sender, zodiacIds) == hash, "Hash fail.");
        require(zodiacIds.length == 12, "Need 12 zodiacs.");
        require(capsules.ownerOf(tokenId) == msg.sender, "You don't own this Capsule.");
        require(!unlockedAnimated[tokenId], "Already unlocked.");

        unlockedAnimated[tokenId] = true;

        bulkTransfer(zodiacIds);
    }

    function unlockSwappableBackgroundsWithZodiac(uint256 zodiacId, uint256 tokenId) external {
        require(!unlockedSwappableBackgrounds[tokenId], "Already unlocked.");
        require(capsules.ownerOf(tokenId) == msg.sender, "You don't own this Capsule.");

        unlockedSwappableBackgrounds[tokenId] = true;

        zodiacs.transferFrom(_msgSender(), address(this), zodiacId);
    }
}