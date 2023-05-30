// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IMillionPieces.sol";
import "./helpers/AccessControl.sol";
import "./helpers/ERC721.sol";


/**
 * @title MillionPieces
 */
contract MillionPieces is ERC721, IMillionPieces, AccessControl {
    using SafeMath for uint256;

    string[] internal _availableArtworks;

    uint256 public constant NFTS_PER_ARTWORK = 10000;
    uint256 public constant SPECIAL_SEGMENTS_COUNT = 20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER");
    bytes32 public constant PRIVILEGED_MINTER_ROLE = keccak256("PRIVILEGED_MINTER");

    event NewArtworkCreated(uint256 id, string name);
    event TokenUriChanged(uint256 token, string uri);
    event BaseUriChanged(string uri);

    constructor (address proxyRegistryAddress) public ERC721("Million Pieces", "MILLION-PIECES", proxyRegistryAddress) {
        emit NewArtworkCreated(_availableArtworks.length, "world-in-pieces");

        _availableArtworks.push("world-in-pieces");
    }

    //  --------------------
    //  GETTERS
    //  --------------------

    function exists(uint256 tokenId) public view override returns (bool) {
        return _exists(tokenId);
    }

    function isValidArtworkSegment(uint256 tokenId) public view override returns (bool) {
        return tokenId > 0 && NFTS_PER_ARTWORK.mul(_availableArtworks.length) >= tokenId;
    }

    function isSpecialSegment(uint256 tokenId) public pure override returns (bool) {
        return (tokenId % NFTS_PER_ARTWORK) < SPECIAL_SEGMENTS_COUNT;
    }

    function getArtworkName(uint256 id) public view override returns (string memory) {
        return _availableArtworks[id];
    }

    //  --------------------
    //  SETTERS PROTECTED
    //  --------------------

    function createArtwork(string calldata name) external override {
        require(hasRole(DEVELOPER_ROLE, msg.sender), "createArtwork: Unauthorized access!");

        emit NewArtworkCreated(_availableArtworks.length, name);

        _availableArtworks.push(name);
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external override {
        require(hasRole(DEVELOPER_ROLE, msg.sender), "setTokenURI: Unauthorized access!");

        _setTokenURI(tokenId, uri);

        emit TokenUriChanged(tokenId, uri);
    }

    function setBaseURI(string calldata baseURI) external override {
        require(hasRole(DEVELOPER_ROLE, msg.sender), "setBaseURI: Unauthorized access!");

        _setBaseURI(baseURI);

        emit BaseUriChanged(baseURI);
    }

    function mintTo(address to, uint256 tokenId) external override {
        require(hasRole(MINTER_ROLE, msg.sender), "mintTo: Unauthorized access!");
        require(isValidArtworkSegment(tokenId), "mintTo: This token unavailable!");
        require(!isSpecialSegment(tokenId), "mintTo: The special segments can not be minted with this method!");

        string memory uri = _generateTokenUri(tokenId);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function mintToSpecial(address to, uint256 tokenId) external override {
        require(hasRole(PRIVILEGED_MINTER_ROLE, msg.sender), "mintToSpecial: Unauthorized access!");
        require(isValidArtworkSegment(tokenId), "mintToSpecial: This token unavailable!");
        require(isSpecialSegment(tokenId), "mintToSpecial: The simple segments can not be minted with this method!");

        string memory uri = _generateTokenUri(tokenId);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    //  --------------------
    //  INTERNAL
    //  --------------------

    function _generateTokenUri(uint256 tokenId) internal view returns (string memory) {
      return _uriStringConcat(
          _availableArtworks[tokenId.add(1).div(NFTS_PER_ARTWORK)],
          '/',
          _uintToString(tokenId)
      );
    }

    function _uriStringConcat(string memory _a, string memory _b, string memory _c)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_a, _b, _c));
    }

    function _uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }

        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number != 0) {
            bstr[k--] = byte(uint8(48 + number % 10));
            number /= 10;
        }

        return string(bstr);
    }
}