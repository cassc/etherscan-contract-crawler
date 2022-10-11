// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "openzeppelin-contracts-v4.6.0/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts-v4.6.0/contracts/metatx/ERC2771Context.sol";

import "../deploymentBaseball/MinterAccess.sol";

contract BaseTokens is ERC2771Context, MinterAccess, ERC721 {
    /// @dev A mapping from token ids to their sha256 IPFS hash
    mapping(uint256 => bytes32) public cards;

    /// @dev Base URI
    string private baseURI;

    event CardAdded(
        uint256 indexed cardId,
        uint256 indexed playerId,
        uint16 indexed season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata
    );

    constructor(
        string memory name,
        string memory symbol,
        address relayAddress
    ) ERC2771Context(relayAddress) ERC721(name, symbol) {}

    /// @dev Get the maximum number of cards per season and scarcity level
    function getScarcityLimit(uint16 season, uint8 scarcity)
        public
        view
        returns (uint256)
    {
        return _getScarcityLimit(season, scarcity);
    }

    /// @dev Set the prefix for the tokenURIs.
    function setTokenURIPrefix(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function mint(
        bytes calldata blob,
        bytes32 metadata,
        address to
    ) public onlyMinter returns (uint256) {
        (
            uint256 playerId,
            uint16 season,
            uint8 scarcity,
            uint16 serialNumber
        ) = abi.decode(blob, (uint256, uint16, uint8, uint16));

        require(
            serialNumber >= 1 &&
                serialNumber <= _getScarcityLimit(season, scarcity),
            "Invalid serial number"
        );

        uint256 cardId = _computeTokenId(
            playerId,
            season,
            scarcity,
            serialNumber
        );

        require(cards[cardId] == 0, "Card already exists");

        cards[cardId] = metadata;

        _safeMint(to, cardId);

        emit CardAdded(
            cardId,
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata
        );

        return cardId;
    }

    function transfer(
        address from,
        address to,
        bytes calldata blob
    ) public {
        (
            uint256 playerId,
            uint16 season,
            uint8 scarcity,
            uint16 serialNumber
        ) = abi.decode(blob, (uint256, uint16, uint8, uint16));

        uint256 tokenId = _computeTokenId(
            playerId,
            season,
            scarcity,
            serialNumber
        );

        safeTransferFrom(from, to, tokenId);
    }

    function _getScarcityLimit(
        uint16, // season
        uint8 // scarcity
    ) internal view virtual returns (uint256) {
        return 0;
    }

    function _computeTokenId(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        playerId,
                        season,
                        uint256(scarcity),
                        serialNumber
                    )
                )
            );
    }

    // prettier-ignore
    function _msgSender() internal view override(ERC2771Context, Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    // prettier-ignore
    function _msgData() internal view override(ERC2771Context, Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, MinterAccess)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId);
    }

    function getCard(uint256 cardId) external view returns (bytes32) {
        return cards[cardId];
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}