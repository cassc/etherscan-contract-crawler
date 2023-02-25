// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 🧑‍🌾

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./SignedAllowlists.sol";
import "./TokenRenderer.sol";
import "./Utils.sol";

contract DaylightScoutsHarvester is
    ERC721,
    ERC721Burnable,
    ERC721Enumerable,
    Pausable,
    Ownable,
    SignedAllowlists
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    TokenRenderer private _getTokenUriAddress;
    bool private _isUriAddressFrozen;
    uint256 private _minimum;
    string private _singularName;

    constructor(
        string memory name,
        string memory code,
        uint256 minimum,
        string memory singularName,
        TokenRenderer getTokenUriAddress
    ) ERC721(name, code) SignedAllowlists(name) {
        _getTokenUriAddress = getTokenUriAddress;
        _minimum = minimum;
        _singularName = singularName;
        _pause();
    }

    // MIN GETTER
    // ----------
    function getMinimum() public view returns (uint256) {
        return _minimum;
    }

    // PAUSE / UNPAUSE
    // ---------------

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // OPENSEA METADATA
    // ----------------

    function contractURI() public view returns (string memory) {
        bytes memory json = abi.encodePacked(
            '{"name": "',
            name(),
            '","description": "The ',
            _singularName,
            " rank is awarded to Daylight Scouts who have submitted ",
            Utils.toString(_minimum),
            " or more accepted abilities. ",
            _singularName,
            ' holders get access to special features on Daylight.xyz. Together, the Scout community works to help everyone discover what their wallet address can do.\\n\\nThis collection is soulbound.", "image": "https://www.daylight.xyz/images/scouts/',
            _singularName,
            '.png", "external_link": "https://www.daylight.xyz" }'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Utils.base64Encode(json)
                )
            );
    }

    // URI
    // ---

    // This cannot be undone!
    function freezeUriAddress() public onlyOwner {
        _isUriAddressFrozen = true;
    }

    modifier whenUriNotFrozen() {
        require(!_isUriAddressFrozen, "URI getter is frozen");
        _;
    }

    function setTokenRendererAddress(
        TokenRenderer newAddress
    ) public onlyOwner whenUriNotFrozen {
        _getTokenUriAddress = newAddress;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        return _getTokenUriAddress.getTokenURI(tokenId, _singularName);
    }

    // MINTING
    // -------

    function allowlistMint(
        bytes calldata signature
    ) public whenNotPaused requiresAllowlist(signature) {
        require(balanceOf(msg.sender) == 0, "One pass per person");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function safeMint(address to) public onlyOwner {
        require(balanceOf(to) == 0, "One pass per person");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // SOULBINDING
    // -----------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);

        // Revert if transfers are not from the 0 address
        // and not to the 0 address or the null address
        if (
            from != address(0) &&
            to != address(0) &&
            to != 0x000000000000000000000000000000000000dEaD
        ) {
            revert("Token is soulbound");
        }
    }

    // SOLIDITY OVERRIDES
    // ------------------

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}