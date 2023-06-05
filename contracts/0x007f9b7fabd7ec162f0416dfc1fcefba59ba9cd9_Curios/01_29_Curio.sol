// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./lib/CurioBase.sol";

contract Curios is CurioBase {
    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        string memory uri_
    ) CurioBase(name_, symbol_, signer_, uri_) {
        _setDefaultRoyalty(msg.sender, 500);
    }

    // Mint (Public)
    function mintCurioPublic(
        uint tokenId
    ) external payable checkLocked(tokenId) {
        Curio memory curio = fullData(tokenId);
        if (!curio.mintable || !curio.publicMint) {
            revert PublicMintUnavailable();
        }
        if (msg.value < curio.mintPrice) {
            revert InsufficientFunds();
        }
        _mint(_msgSender(), tokenId, 1, "");
    }

    // Mint (With signature)
    function mintCurioSigned(
        bytes calldata signature,
        uint tokenId,
        uint nonce
    ) external payable checkLocked(tokenId) {
        Curio memory curio = fullData(tokenId);
        if (!verify(signature, _msgSender(), tokenId, nonce)) {
            revert InvalidSignature();
        }
        if (msg.value < curio.mintPrice) {
            revert InsufficientFunds();
        }
        _mint(_msgSender(), tokenId, 1, "");
    }

    // Airdrop
    function airdropCurio(
        address to_,
        uint tokenId
    ) external payable onlyOwner checkLocked(tokenId) {
        _mint(to_, tokenId, 1, "");
    }

    function airdropCurioOneToMany(
        address[] calldata to_,
        uint tokenId
    ) external payable onlyOwner checkLocked(tokenId) {
        uint howMany = to_.length;

        for (uint i = 0; i < howMany; ) {
            _mint(to_[i], tokenId, 1, "");
            unchecked {
                ++i;
            }
        }
    }

    function airdropCurioManyToMany(
        address[] calldata to_,
        uint[] calldata ids,
        uint[] calldata amts
    ) external payable onlyOwner {
        uint howMany = to_.length;

        if (howMany != ids.length || howMany != amts.length) {
            revert MismatchedParameters();
        }

        for (uint i = 0; i < howMany; ) {
            _checkLocked(ids[i]);
            _mint(to_[i], ids[i], amts[i], "");
            unchecked {
                ++i;
            }
        }
    }

    // Initialize Wearable

    function newCurio(uint8 slotId) external payable onlyOwner {
        Curio memory curio;
        curio.slotId = slotId;
        _createNewItem(curio);
    }

    function newCurioMint(
        uint8 slotId,
        uint80 mintPrice,
        uint16 maxSupply,
        uint8 slotCollision,
        bool soulbound,
        bool mintable,
        uint16 minGeneration
    ) external payable onlyOwner {
        Curio memory curio;
        curio.slotId = slotId;
        curio.mintPrice = mintPrice;
        curio.maxSupply = maxSupply;
        curio.slotCollision = slotCollision;
        curio.soulbound = soulbound;
        curio.mintable = mintable;
        curio.minGeneration = minGeneration;
        _createNewItem(curio);
    }

    function newThread(uint8[] calldata slotIds) external payable {
        uint howMany = slotIds.length;

        for (uint i = 0; i < howMany; ) {
            Curio memory curio;
            curio.slotId = slotIds[i];
            _createNewItem(curio);

            unchecked {
                ++i;
            }
        }
    }
}