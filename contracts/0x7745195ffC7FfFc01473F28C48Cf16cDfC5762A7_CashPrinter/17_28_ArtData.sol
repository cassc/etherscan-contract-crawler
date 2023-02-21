// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

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
    address delegate;
    string name;
    string symbol;
    string description;
    uint32 color1;
    uint32 color2;
}

struct ArtUpdate {
    uint id;
    string name;
    string symbol;
    string description;
    uint32 color1;
    uint32 color2;
}

struct Art {
    uint id;
    ArtMeta meta;
    address delegate;
    string name;
    string symbol;
    string description;
    uint32 color1;
    uint32 color2;
    uint createdAt;
}

contract ArtData is ArtMeta, ERC721 {
    uint private _tokenCount;

    mapping(uint => Art) private _art;

    event CreateArt(
        uint indexed id,
        ArtMeta indexed meta,
        address indexed minter,
        address delegate,
        string name,
        string symbol,
        string description,
        uint32 color1,
        uint32 color2,
        uint timestamp
    );

    event UpdateArt(
        uint indexed id,
        string name,
        string symbol,
        string description,
        uint32 color1,
        uint32 color2,
        uint timestamp
    );

    event DelegateArt(
        uint indexed id,
        address indexed delegate,
        uint timestamp
    );

    function getArt(uint tokenId) external view returns (Art memory) {
        return _requireArt(tokenId);
    }

    function delegateOf(uint artId) public view returns (address) {
        return _requireArt(artId).delegate;
    }

    function tokenCount() external view returns (uint) {
        return _tokenCount;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        return _requireArt(tokenId).meta.tokenDataURI(tokenId);
    }

    function tokenData(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenData(tokenId);
    }

    function tokenImage(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenImage(tokenId);
    }

    function tokenDataURI(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenDataURI(tokenId);
    }

    function tokenImageURI(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenImageURI(tokenId);
    }

    function _requireArt(uint tokenId) internal view returns (Art memory) {
        require(
            tokenId > 0 && tokenId <= _tokenCount,
            "Art not found"
        );
        return _art[tokenId];
    }

     /*$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$
    | $$__  $$ /$$__  $$|__  $$__//$$__  $$
    | $$  \ $$| $$  \ $$   | $$  | $$  \ $$
    | $$  | $$| $$$$$$$$   | $$  | $$$$$$$$
    | $$  | $$| $$__  $$   | $$  | $$__  $$
    | $$  | $$| $$  | $$   | $$  | $$  | $$
    | $$$$$$$/| $$  | $$   | $$  | $$  | $$
    |_______/ |__/  |__/   |__/  |__/  |_*/

    function createArt(ArtParams memory params, ArtMeta meta) external returns (uint) {
        Art storage art = _art[++_tokenCount];

        art.id = _tokenCount;
        art.meta = meta;
        art.name = params.name;
        art.symbol = params.symbol;
        art.description = params.description;
        art.color1 = params.color1;
        art.color2 = params.color2;
        art.delegate = params.delegate;
        art.createdAt = block.timestamp;

        _safeMint(
            params.minter,
            art.id,
            new bytes(0)
        );

        emit CreateArt(
            art.id,
            art.meta,
            params.minter,
            art.delegate,
            art.name,
            art.symbol,
            art.description,
            art.color1,
            art.color2,
            block.timestamp
        );

        return _tokenCount;
    }

    function updateArt(ArtUpdate calldata params) external returns (uint) {
        Art storage art = _art[params.id];

        require(
            msg.sender == ownerOf(params.id),
            "Caller is not the owner"
        );

        art.name = params.name;
        art.symbol = params.symbol;
        art.description = params.description;
        art.color1 = params.color1;
        art.color2 = params.color2;

        emit UpdateArt(
            art.id,
            art.name,
            art.symbol,
            art.description,
            art.color1,
            art.color2,
            block.timestamp
        );

        return params.id;
    }

    function delegateArt(uint artId, address delegate) external returns (uint) {
        require(
            msg.sender == ownerOf(artId)
            || msg.sender == delegateOf(artId),
            "Caller is not the owner or delegate"
        );

        Art storage art = _art[artId];
        art.delegate = delegate;

        emit DelegateArt(
            artId,
            delegate,
            block.timestamp
        );

        return artId;
    }

    function _afterTokenTransfer(
        address from, address, uint tokenId, uint
    ) internal virtual override {
        if (from != address(0)) {
            Art storage art = _art[tokenId];
            art.delegate = address(0);
        }
    }

    constructor() ERC721("Art", "ART") {}
}