//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { ERC721ABurnable } from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import { ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * >>> Join the Resistance <<<
 * >>>   https://nfa.gg/   <<<
 * @title   NonFungibleArcade Pack
 * @notice  NFTs representing packs of items and passes
 * @author  BowTiedPickle
 */
contract PackNFT is ERC721A, ERC721ABurnable, ERC721AQueryable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice  Base URI for token URIs
    string public baseURI;

    /**
     * @notice  Construct a new PackNFT contract
     * @param   _owner      Owner of the contract
     * @param   baseURI_    Base URI for token URIs
     */
    constructor(address _owner, string memory baseURI_) ERC721A("NFArcade Pack", "NFA-PACK") {
        if (_owner == address(0)) revert Pack__ZeroAddress();

        baseURI = baseURI_;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    // ---------- Minter ----------

    /**
     * @notice  Mint a new token
     * @param   _to         Address to mint to
     * @param   _amount     Amount to mint
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    // ---------- Admin ----------

    /**
     * @notice  Set a new base URI
     * @param   _newURI     New URI string
     */
    function setBaseURI(string memory _newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit NewURI(baseURI, _newURI);
        baseURI = _newURI;
    }

    // ---------- Overrides ----------

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC721A, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length != 0 ? string(abi.encodePacked(baseURI_, _toString(tokenId), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ---------- Events ----------

    event NewURI(string _oldURI, string _newURI);

    // ---------- Errors ----------

    error Pack__ZeroAddress();
}