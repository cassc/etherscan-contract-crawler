// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../contracts/SkullDungeon.sol";

//
// ██████╗░░█████╗░░█████╗░███╗░░░███╗░██████╗██╗░░██╗██╗░░░██╗██╗░░░░░██╗░░░░░
// ██╔══██╗██╔══██╗██╔══██╗████╗░████║██╔════╝██║░██╔╝██║░░░██║██║░░░░░██║░░░░░
// ██║░░██║██║░░██║██║░░██║██╔████╔██║╚█████╗░█████═╝░██║░░░██║██║░░░░░██║░░░░░
// ██║░░██║██║░░██║██║░░██║██║╚██╔╝██║░╚═══██╗██╔═██╗░██║░░░██║██║░░░░░██║░░░░░
// ██████╔╝╚█████╔╝╚█████╔╝██║░╚═╝░██║██████╔╝██║░╚██╗╚██████╔╝███████╗███████╗
// ╚═════╝░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═════╝░╚═╝░░╚═╝░╚═════╝░╚══════╝╚══════╝
//
// ██████╗░██╗░░░██╗███╗░░██╗░██████╗░███████╗░█████╗░███╗░░██╗
// ██╔══██╗██║░░░██║████╗░██║██╔════╝░██╔════╝██╔══██╗████╗░██║
// ██║░░██║██║░░░██║██╔██╗██║██║░░██╗░█████╗░░██║░░██║██╔██╗██║
// ██║░░██║██║░░░██║██║╚████║██║░░╚██╗██╔══╝░░██║░░██║██║╚████║
// ██████╔╝╚██████╔╝██║░╚███║╚██████╔╝███████╗╚█████╔╝██║░╚███║
// ╚═════╝░░╚═════╝░╚═╝░░╚══╝░╚═════╝░╚══════╝░╚════╝░╚═╝░░╚══╝
//

contract DoomskullDungeon is SkullDungeon {
    /// ============ Immutable storage ============
    ///
    uint256 public constant DOOMSKULL_MAX_SUPPLY = 666;

    uint256 public constant DOOMSKULL_START_ID = 10000;

    string internal DOOMSKULL_PROVENANCE_HASH;

    /// ============ Mutable storage ============
    ///
    bool public doomskullBreedingActive;
    uint256 public doomskullTokenCounter;

    bool public doomskullMetadataFinalised;
    string internal _doomskullPlaceholderURI;
    mapping(uint256 => string) internal _doomskullCIDs;

    mapping(address => bool) internal _authorised;
    address[] public authorisedLog;

    /// ============ Modifiers ============
    ///
    modifier onlyAuthorised() {
        require(_authorised[_msgSender()], "The sender is not authorised");
        _;
    }

    constructor(
        address signer,
        string memory baseURI,
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        uint256 linkFee
    ) SkullDungeon(signer, baseURI, vrfCoordinator, linkToken, keyHash, linkFee) {
        require(MAX_SUPPLY <= DOOMSKULL_START_ID);
        doomskullBreedingActive = false;
        doomskullTokenCounter = 0;

        doomskullMetadataFinalised = false;
        _doomskullPlaceholderURI = baseURI;
    }

    function breed(uint256 tokenId) external onlyAuthorised nonReentrant returns (uint256) {
        require(doomskullBreedingActive, "Doomskull breeding not active");
        require(doomskullTokenCounter < DOOMSKULL_MAX_SUPPLY, "Doomskull max supply exceeded");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "Not the owner");

        uint256 newTokenID = DOOMSKULL_START_ID + doomskullTokenCounter;
        _burn(tokenId);
        _safeMint(_msgSender(), newTokenID);
        doomskullTokenCounter++;
        return newTokenID;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (tokenId < DOOMSKULL_START_ID) {
            return super.tokenURI(tokenId);
        }
        if (bytes(_doomskullCIDs[tokenId]).length > 0) {
            return string(abi.encodePacked("ipfs://", _doomskullCIDs[tokenId]));
        }
        return _doomskullPlaceholderURI;
    }

    function doomskullProvenanceHash() public view returns (string memory) {
        require(
            bytes(DOOMSKULL_PROVENANCE_HASH).length != 0,
            "Doomskull provenance hash is not set"
        );
        return DOOMSKULL_PROVENANCE_HASH;
    }

    /// ============ ADMIN functions ============

    function setDoomskullBreedingActive(bool active) public onlyOwner {
        doomskullBreedingActive = active;
    }

    function finaliseDoomskullMetadata() public onlyOwner {
        require(!doomskullMetadataFinalised, "Doomskull metadata already finalised");
        doomskullMetadataFinalised = true;
    }

    function setDoomskullPlaceholderURI(string memory placeholderURI) public onlyOwner {
        _doomskullPlaceholderURI = placeholderURI;
    }

    function setDoomskullCID(uint256 tokenId, string memory tokenCID) public onlyOwner {
        require(!doomskullMetadataFinalised, "Doomskull metadata already finalised");
        _doomskullCIDs[tokenId] = tokenCID;
    }

    function setDoomskullCIDs(uint256[] memory tokenIds, string[] memory tokenCIDs)
        public
        onlyOwner
    {
        require(!doomskullMetadataFinalised, "Doomskull metadata already finalised");
        require(tokenIds.length == tokenCIDs.length, "Arrays of different sizes");
        require(tokenIds.length <= 100, "Max 100 token IDs");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _doomskullCIDs[tokenIds[i]] = tokenCIDs[i];
        }
    }

    function setDoomskullProvenanceHash(string memory _provenanceHash) public onlyOwner {
        require(
            bytes(DOOMSKULL_PROVENANCE_HASH).length == 0,
            "Doomskull provenance hash is already set"
        );
        DOOMSKULL_PROVENANCE_HASH = _provenanceHash;
    }

    function authorise(address toAuth) public onlyOwner {
        _authorised[toAuth] = true;
        authorisedLog.push(toAuth);
    }

    function unauthorise(address toUnauth) public onlyOwner {
        _authorised[toUnauth] = false;
    }
}