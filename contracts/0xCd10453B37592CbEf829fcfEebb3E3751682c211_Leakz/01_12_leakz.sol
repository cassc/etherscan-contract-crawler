// SPDX-License-Identifier: MIT
// Creator: [NOT LEAKED YET]

pragma solidity ^0.8.11;

//  ooooo                            oooo                   
//  `888'                            `888                   
//   888          .ooooo.   .oooo.    888  oooo    oooooooo
//   888         d88' `88b `P  )88b   888 .8P'    d'""7d8P 
//   888         888ooo888  .oP"888   888888.       .d8P'  
//   888       o 888    .o d8(  888   888 `88b.   .d8P'  .P
//  o888ooooood8 `Y8bod8P' `Y888""8o o888o o888o d8888888P 

// Let's have some fun with this ... 50b

// This contract is fairly basic. It takes a message and embeds it
// within an NFT. Only the NFT owner can reveal the message. If you
// decide to use the contract outside of Giga City environment you
// need to encrypt the message before you mint it.

// =============================================================
//                       FUCKING ROCKSTARS
// =============================================================

import "solmate/src/utils/ReentrancyGuard.sol";
import "solmate/src/utils/LibString.sol";

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// =============================================================
//                            LEAKERZ
// =============================================================

interface Leaker {
  function balanceOf(address owner) external view returns(uint256);
}

// =============================================================
//                            ERRORS
// =============================================================

error LeakzNotBooted();
error LeakzOverflow();
error NoCashForLeak();
error NoLeakHere();
error NotYourLeak();

// =============================================================
//                             LEAKZ
// =============================================================

/**
 * Leakz
 *
 * The main thing in its full glory. There isn't much going on really.
 */
contract Leakz is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, ReentrancyGuard {

    // =============================================================
    //                            HELPERS
    // =============================================================

    // Converts a uint256 to its ASCII string representation.
    using LibString for uint256;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Secret handshakes were made?
    address[] private _leakerz;

    // Keeping the status of public mint
    bool public _leakzBooted = false;

    // We might want to include a mint price for the mint
    // so that ppl don't mint completely random shit.
    // We should aim for having a lower supply of leakz in circulation.
    uint256 public _leakzCost = 0;

    // Max amount of leakz in circularion. You wanna leak some more? Burn it.
    uint256 public _leakzMemorySize = 10000;

    // Mapping of all the leakz messages.
    mapping(uint256 => string) internal _leakz;

    // Cover image
    string public _cover;
    
    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================

    constructor() ERC721A('Leakz', 'LEAKZ') {}

    // =============================================================
    //                            MODIFIERS
    // =============================================================

    /**
     * Can you leak? The whole modifier is unnecessary as it is used
     * only in a single function. I just dig it.
     */
    modifier leakable() {
        // We must be public first.
        if (!_leakzBooted) revert LeakzNotBooted();

        // When you are leaking X the ammount must no go beyond the max supply.
        if (totalSupply() + 1 > _leakzMemorySize) revert LeakzOverflow();

        // If you own any NFT from the collections below, you will be minting for free
        uint price = _leakzCost;

        for (uint i = 0; i<_leakerz.length; i++) {
            if (_leakerz[i] != address(0)) {
                if (Leaker(_leakerz[i]).balanceOf(msg.sender) > 0) {
                    price = 0;
                    break;
                }
            }
        }

        // You need to have enough ETH to pay for the leak. In case you need to pay something.
        if (msg.value < price) revert NoCashForLeak();

        // The rest of the function is executed heret.
        _;
    }

    // =============================================================
    //                              MINT
    // =============================================================

    function leak(string calldata message) external payable leakable() {
      uint256 currentIndex = _nextTokenId();
      _leakz[currentIndex] = message;
      _mint(_msgSender(), 1);
    }

    // =============================================================
    //                            READER
    // =============================================================

    function reveal(uint256 tokenId) external view returns(string memory) {
        if (_msgSender() != ownerOf(tokenId)) revert NotYourLeak();
        return _leakz[tokenId];
    }

    // =============================================================
    //                            BURN
    // =============================================================

    function burn(uint256 tokenId) public override {
        if (_msgSender() !=  ownerOf(tokenId)) revert NotYourLeak();
        _burn(tokenId);
    }

    // Making the burn counter public
    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    // =============================================================
    //                       SETTERS & GETTERS
    // =============================================================
    
    // Setter for boot status
    function setBoot(bool state) public onlyOwner {
        _leakzBooted = state;
    }

    // Setter for cover image
    function setCover(string calldata newUrl) public onlyOwner {
        _cover = newUrl;
    }

    // Setter for cost
    function setCost(uint256 cost) public onlyOwner {
        _leakzCost = cost;
    }

    // Setter for max supply
    function setMemory(uint256 newMemory) public onlyOwner {
        _leakzMemorySize = newMemory;
    }

    // =============================================================
    //                             LEAKERZ
    // =============================================================

    // If contract is added, the owners of these NFTs will
    // be able to mint for free
    function addLeaker(address _address) public onlyOwner {
        _leakerz.push(_address);
    }

    // Removing these collections from the free access
    function removeLeaker(uint256 index) public onlyOwner {
        delete _leakerz[index];
    }

    // =============================================================
    //                            METADATA
    // =============================================================


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A,IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert NoLeakHere();

        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Leak #', tokenId.toString(), '",',
                '"description": "For your own safety burn after use.",',
                '"image": "', _cover, '",'
                '"attributes": []'
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    // =============================================================
    //                            WITHDRAW
    // =============================================================

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
}