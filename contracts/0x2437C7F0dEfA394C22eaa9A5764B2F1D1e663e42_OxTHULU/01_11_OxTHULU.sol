// SPDX-License-Identifier: GPL-3.0
// 0xTHULU Relic of Membership V2
// Pausable | Burnable | Upgradable
// NFT Content Sole Copyright Owner & Royalty Receiver 
// ======================================================
// 0xTHULU Inc., Columbus, Ohio - USA. https://0xthulu.io
// ======================================================
// Non-Fungible Token Standard : ERC721a (forked from OpenZeppelin & Azuki)
// Smart Contracts Deployed by www.BLAZE.ws

pragma solidity >=0.7.0 <0.9.0;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

contract OxTHULU is ERC721AUpgradeable, OwnableUpgradeable, PausableUpgradeable {

    // Max Total Supply
    uint256 MAX_SUPPLY;

    // IPFS BASE URI
    string public baseURI;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("0xTHULU Relic of Membership V2", "0xROMv2");
        __Ownable_init();
        __Pausable_init();
        MAX_SUPPLY = 11138;
        baseURI = "https://ipfs.perma.store/content/bafybeicjuwa5tzu6zm2s5k7uvb3q55zwzdedn3zxbmbzn6wqpx5xmume4m/";
    }

    function mint(address to, uint256 quantity) external onlyOwner whenNotPaused  {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // burn token
    function burn(uint256 tokenId) external whenNotPaused {
        _burn(tokenId, true);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused{
        // require(!paused(), "ERC721Pausable: token transfer while paused");
    } 

    // To change the starting token ID
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}