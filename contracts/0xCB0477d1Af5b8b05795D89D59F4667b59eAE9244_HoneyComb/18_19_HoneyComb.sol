// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "dual-ownership-nft/MultisigOwnable.sol";
import "solmate/utils/LibString.sol";

import {ERC721AQueryable, ERC721A, IERC721A} from "ERC721A/extensions/ERC721AQueryable.sol";

import {IHoneyComb} from "./IHoneyComb.sol";
import {GameRegistryConsumer} from "./GameRegistry.sol";
import {Constants} from "./GameLib.sol";

contract HoneyComb is IHoneyComb, GameRegistryConsumer, ERC721AQueryable, MultisigOwnable {
    using LibString for uint256;

    constructor(address gameRegistry_) ERC721A("Honey Comb", "HONEYCOMB") GameRegistryConsumer(gameRegistry_) {}

    // metadata URI
    string public _baseTokenURI = "https://www.0xhoneyjar.xyz/";
    bool public isGenerated; // once the token is generated we can append individual tokenIDs

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyRealOwner {
        _baseTokenURI = baseURI;
    }

    function setGenerated(bool generated_) external onlyRealOwner {
        isGenerated = generated_;
    }

    /// @notice Token URI will be a generic URI at first.
    /// @notice When isGnerated is set to true, it will concat the baseURI & tokenID
    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return isGenerated ? string.concat(baseURI, _toString(tokenId)) : baseURI;
    }

    /// @notice create honeycomb for an address.
    /// @dev only callable by the MINTER role
    function mint(address to) public onlyRole(Constants.MINTER) returns (uint256) {
        _mint(to, 1);
        return _nextTokenId() - 1; // To get the latest mintID
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    /// @notice mint multiple.
    /// @dev only callable by the MINTER role
    function batchMint(address to, uint256 amount) external onlyRole(Constants.MINTER) {
        _mint(to, amount);
    }

    /// @notice burn the honeycomb tokens. Nothing will have the burn role upon initialization
    /// @notice This will be used for future game-mechanics
    /// @dev only callable by the BURNER role
    function burn(uint256 _id) external override onlyRole(Constants.BURNER) {
        _burn(_id, true);
    }
}