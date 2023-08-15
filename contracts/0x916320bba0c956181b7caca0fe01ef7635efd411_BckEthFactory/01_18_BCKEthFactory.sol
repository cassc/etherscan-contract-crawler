// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract BckEthFactory is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    Pausable,
    AccessControl
{
    // MinterRole
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // MetadataBaseUri
    string public bckBaseURI = "https://ipfs.io/ipfs/";
    // Total buildings minted
    uint256 public currentTokenId;

    // EVENTS
    event mintCardEvent(address to, uint256 tokenId);

    constructor() ERC721("BCK ETH Factory", "BCKEthFactory") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // OVERRIDES
    function _baseURI() internal view virtual override returns (string memory) {
        return bckBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        ERC721URIStorage._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    // EXTERNAL FUNCTIONS
    // TX

    /**
     * mint next token
     */
    function mintNext(
        uint256 _amount,
        address _receiver,
        string memory _path
    ) external whenNotPaused onlyRole(MINTER_ROLE) {
        require(
            !(_exists(currentTokenId + 1)),
            string(
                abi.encodePacked(
                    "TokenId ",
                    Strings.toString(currentTokenId + 1),
                    " already exists"
                )
            )
        );

        for (uint256 i = 0; i < _amount; i++) {
            currentTokenId++;

            _safeMint(_receiver, currentTokenId);
            _setTokenURI(
                currentTokenId,
                string(
                    abi.encodePacked(
                        _path,
                        Strings.toString(currentTokenId),
                        ".json"
                    )
                )
            );
            emit mintCardEvent(_receiver, currentTokenId);
        }
    }

    /**
     * mint specific token
     */
    function mintSpecific(
        uint256 _tokenId,
        address _receiver,
        string memory _path
    ) external whenNotPaused onlyRole(MINTER_ROLE) {
        require(
            !(_exists(_tokenId)),
            string(
                abi.encodePacked(
                    "TokenId ",
                    Strings.toString(_tokenId),
                    " already exists"
                )
            )
        );

        _safeMint(_receiver, _tokenId);
        _setTokenURI(
            _tokenId,
            string(abi.encodePacked(_path, Strings.toString(_tokenId), ".json"))
        );
        emit mintCardEvent(_receiver, _tokenId);
    }

    /**
     * mint specific token(s) // ONLY ADMIN
     */
    function mintSpecificBatch(
        uint256[] memory _tokenIds,
        address _receiver,
        string memory _path
    ) external whenNotPaused onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                !(_exists(_tokenIds[i])),
                string(
                    abi.encodePacked(
                        "TokenId ",
                        Strings.toString(_tokenIds[i]),
                        " already exists"
                    )
                )
            );

            _safeMint(_receiver, _tokenIds[i]);
            _setTokenURI(
                _tokenIds[i],
                string(
                    abi.encodePacked(
                        _path,
                        Strings.toString(_tokenIds[i]),
                        ".json"
                    )
                )
            );
            emit mintCardEvent(_receiver, _tokenIds[i]);
        }
    }

    // ADMIN
    function setBCKBaseUri(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bckBaseURI = _uri;
    }

    function setTokenUris(uint256[] memory _tokenIds, string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _setTokenURI(
                _tokenIds[i],
                string(
                    abi.encodePacked(_uri, "/", Strings.toString(_tokenIds[i]))
                )
            );
        }
    }

    function getMinterRole()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes32)
    {
        return MINTER_ROLE;
    }

    function setCurrentTokenId(uint256 _current)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        currentTokenId = _current;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) _pause();
        else _unpause();
    }
}