//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GalacticApes is ERC721, Ownable {
    event Migrated(uint256 indexed tokenId);

    string private baseURI;

    IERC1155 public OpenSeaStore;
    IERC721 public GapeContract;

    constructor(
        string memory name,
        string memory symbol,
        address openSeaStore,
        address gapeContract
    ) ERC721(name, symbol) {
        OpenSeaStore = IERC1155(openSeaStore);
        GapeContract = IERC721(gapeContract);
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender,
            "Sender is not the token owner"
        );
        _;
    }

    function getGalacticApeId(uint256 _id) external pure returns (uint256) {
        return _getGalacticApeId(_id);
    }

    function _getGalacticApeId(uint256 _id) internal pure returns (uint256) {
        require(
            _id >> 96 ==
                0x000000000000000000000000DF79D424F687ACDF388939EC6ADE2A37B9329806,
            "Invalid token"
        );
        require(
            _id &
                0x000000000000000000000000000000000000000000000000000000ffffffffff ==
                1,
            "Invalid token"
        );

        _id =
            (_id &
                0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >>
            40;

        require(_id > 0 && _id <= 157, "Invalid token");

        if (_id == 101) return _id - 2;
        else if (_id > 101 && _id < 120) return _id - 3;
        else if (_id > 119 && _id < 151) return _id - 4;
        else if (_id > 150 && _id < 155) return _id - 5;
        else if (_id > 154) return _id - 6;
        return _id;
    }

    function migrateGenesisGapes(uint256[] calldata _tokenIds) external {
        uint256 tokenIdsLength = _tokenIds.length;
        for (uint256 i; i < tokenIdsLength;) {
            uint256 id = _getGalacticApeId(_tokenIds[i]);

            OpenSeaStore.safeTransferFrom(
                msg.sender,
                address(0x000000000000000000000000000000000000dEaD),
                _tokenIds[i],
                1,
                ""
            );

            _mint(msg.sender, id);

            emit Migrated(id);

            unchecked { ++i; }
        }
    }

    function migrateGalacticApes(uint256[] calldata _tokenIds) external {
        uint256 tokenIdsLength = _tokenIds.length;

        require(tokenIdsLength > 0, "tokenIds must not be empty");

        for (uint256 i; i < tokenIdsLength;) {
            // send this galactic ape to the shadow realm
            GapeContract.transferFrom(
                msg.sender,
                address(0x000000000000000000000000000000000000dEaD),
                _tokenIds[i]
            );

            // offset tokens by 1, since we are NOT 0-indexing
            uint256 tokenId = _tokenIds[i] + 151 + 1;

            _mint(msg.sender, tokenId);

            emit Migrated(tokenId);

            unchecked { ++i; }
        }
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
            ? string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            )
            : "";
    }
}