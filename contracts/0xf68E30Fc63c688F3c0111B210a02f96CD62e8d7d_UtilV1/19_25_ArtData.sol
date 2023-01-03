// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

  /*$$$$$  /$$$$$$$  /$$$$$$$$
 /$$__  $$| $$__  $$|__  $$__/
| $$  \ $$| $$  \ $$   | $$
| $$$$$$$$| $$$$$$$/   | $$
| $$__  $$| $$__  $$   | $$
| $$  | $$| $$  \ $$   | $$
| $$  | $$| $$  | $$   | $$
|__/  |__/|__/  |__/   |_*/

interface ArtMeta {
    function tokenCount() external view returns (uint);
    function tokenData(uint tokenId) external view returns (string memory);
    function tokenImage(uint tokenId) external view returns (string memory);
    function tokenImageURI(uint tokenId) external view returns (string memory);
    function tokenDataURI(uint tokenId) external view returns (string memory);
}

struct ArtParams {
    address minter;
    string name;
    string symbol;
    string color1;
    string color2;
    string description;
    address delegate;
}

struct ArtUpdate {
    uint id;
    string color1;
    string color2;
    string description;
}

struct Art {
    uint id;
    string name;
    string symbol;
    string color1;
    string color2;
    string description;
    uint createdAt;
    address delegate;
    ArtMeta metadata;
}

contract ArtData is ArtMeta, ERC721 {
    uint private _tokenCount;

    mapping(uint => Art) private _art;

    event ArtCreated(
        uint indexed id,
        string name,
        string symbol,
        string color1,
        string color2,
        string description,
        address delegate,
        ArtMeta indexed metadata,
        address indexed minter,
        uint timestamp
    );

    event ArtDelegated(
        uint indexed id,
        address delegate,
        uint timestamp
    );

    event ArtUpdated(
        uint indexed id,
        string color1,
        string color2,
        string description,
        uint timestamp
    );

    function tokenCount() external view returns (uint) {
        return _tokenCount;
    }

    function delegateOf(uint artId) public view returns (address) {
        return _requireArt(artId).delegate;
    }

    function getArt(uint tokenId) external view returns (Art memory) {
        return _requireArt(tokenId);
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        return _requireArt(tokenId).metadata.tokenDataURI(tokenId);
    }

    function tokenData(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).metadata.tokenData(tokenId);
    }

    function tokenImage(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).metadata.tokenImage(tokenId);
    }

    function tokenDataURI(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).metadata.tokenDataURI(tokenId);
    }

    function tokenImageURI(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).metadata.tokenImageURI(tokenId);
    }

    function _requireArt(uint tokenId) internal view returns (Art memory) {
        require(
            tokenId > 0 && tokenId <= _tokenCount,
            "Art not found"
        );
        return _art[tokenId];
    }

      /*$$$$$  /$$   /$$        /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$ /$$   /$$
     /$$__  $$| $$$ | $$       /$$__  $$| $$  | $$ /$$__  $$|_  $$_/| $$$ | $$
    | $$  \ $$| $$$$| $$      | $$  \__/| $$  | $$| $$  \ $$  | $$  | $$$$| $$
    | $$  | $$| $$ $$ $$      | $$      | $$$$$$$$| $$$$$$$$  | $$  | $$ $$ $$
    | $$  | $$| $$  $$$$      | $$      | $$__  $$| $$__  $$  | $$  | $$  $$$$
    | $$  | $$| $$\  $$$      | $$    $$| $$  | $$| $$  | $$  | $$  | $$\  $$$
    |  $$$$$$/| $$ \  $$      |  $$$$$$/| $$  | $$| $$  | $$ /$$$$$$| $$ \  $$
     \______/ |__/  \__/       \______/ |__/  |__/|__/  |__/|______/|__/  \_*/

    function createArt(ArtParams memory params, ArtMeta meta) external returns (uint) {
        Art storage art = _art[++_tokenCount];

        art.id = _tokenCount;
        art.metadata = meta;
        art.name = params.name;
        art.color1 = params.color1;
        art.color2 = params.color2;
        art.symbol = params.symbol;
        art.description = params.description;
        art.delegate = params.delegate;
        art.createdAt = block.timestamp;

        _safeMint(params.minter, art.id, new bytes(0));

        emit ArtCreated(
            art.id,
            art.name,
            art.symbol,
            art.color1,
            art.color2,
            art.description,
            art.delegate,
            art.metadata,
            params.minter,
            block.timestamp
        );

        return art.id;
    }

    function updateArt(ArtUpdate memory params) external returns (uint) {
        Art storage art = _art[params.id];
        require(
            msg.sender == ownerOf(params.id) ||
            msg.sender == art.delegate,
            "Caller is not the owner or delegate"
        );

        art.color1 = params.color1;
        art.color2 = params.color2;
        art.description = params.description;

        emit ArtUpdated(
            art.id,
            art.color1,
            art.color2,
            art.description,
            block.timestamp
        );

        return art.id;
    }

    function delegateArt(address delegate, uint artId) external returns (uint) {
        require(
            msg.sender == ownerOf(artId)
            || msg.sender == delegateOf(artId),
            "Caller is not the owner or delegate"
        );
        
        Art storage art = _art[artId];
        art.delegate = delegate;

        emit ArtDelegated(artId, delegate, block.timestamp);
        return art.id;
    }

    function _afterTokenTransfer(
        address from, address, uint tokenId, uint
    ) internal virtual override {
        if (from != address(0)) {
            Art storage art = _art[tokenId];
            art.delegate = address(0);
        }
    }

    constructor() ERC721("Namespace Studio Art", "STUDIO ART") {}
}