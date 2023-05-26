// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libraries/ContractUri.sol";
import "./libraries/MinterAccess.sol";
import "./libraries/Recoverable.sol";

/**
 * @title TheFallen
 * @notice TheFallen ERC721 NFT collection
 * https://www.samuraisaga.com
 */
contract TheFallen is Ownable, ERC721, MinterAccess, ContractUri, Recoverable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bool public isMetadataLocked;

    uint256 public immutable maxSupply;
    Counters.Counter private _totalSupply;

    string public baseURI;

    mapping(uint256 => bool) public linkedSamurais;
    mapping(uint256 => bool) public linkedOnnas;

    event LockMetadata();

    /**
     * @notice Constructor
     * @param _maxSupply: NFT max totalSupply
     */
    constructor(uint256 _maxSupply) ERC721("TheFallen", "FALLEN") {
        maxSupply = _maxSupply;
    }

    /**
     * @dev Returns the current supply
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    /**
     * @notice Allows the owner to lock the contract
     * @dev Callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(!isMetadataLocked, "Operations: Contract is locked");
        require(bytes(baseURI).length > 0, "Operations: BaseUri not set");
        isMetadataLocked = true;
        emit LockMetadata();
    }

    /**
     * @notice Allows a member of the minters group to mint a token to a specific address
     * @param _to: address to receive the token
     * @param _tokenId: tokenId
     * @dev Callable by minters
     */
    function mint(
        address _to,
        uint256 _tokenId,
        uint8 linkedCollection,
        uint256 linkedId
    ) external onlyMinters {
        require(_totalSupply.current() < maxSupply, "NFT: Total supply reached");

        if (linkedCollection == 0) {
            require(!linkedSamurais[linkedId], "NFT: Samurai already linked");
            linkedSamurais[linkedId] = true;
        } else {
            require(!linkedOnnas[linkedId], "NFT: Onna already linked");
            linkedOnnas[linkedId] = true;
        }

        _totalSupply.increment();
        _mint(_to, _tokenId);
    }

    /**
     * @notice Allows a member of the minters group to mint a batch of tokens to a specific address
     * @param _to: address to receive the token
     * @param _tokenIds: the list of tokenId to mint
     * @param _linkedSamuraiIds: the linked samurais
     * @param _linkedOnnaIds: the linked onna bugeishas
     * @dev Callable by minters
     */
    function mintBatch(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _linkedSamuraiIds,
        uint256[] calldata _linkedOnnaIds
    ) external onlyMinters {
        require(_totalSupply.current() < maxSupply, "NFT: Total supply reached");
        require(_totalSupply.current() + _tokenIds.length <= maxSupply, "NFT: Not enough supply");
        require(_tokenIds.length == _linkedSamuraiIds.length + _linkedOnnaIds.length, "NFT: Invalid linked tokens");

        uint256 i;
        for (i = 0; i < _linkedSamuraiIds.length; i++) {
            require(!linkedSamurais[_linkedSamuraiIds[i]], "NFT: Samurai already linked");
            linkedSamurais[_linkedSamuraiIds[i]] = true;
        }

        for (i = 0; i < _linkedOnnaIds.length; i++) {
            require(!linkedOnnas[_linkedOnnaIds[i]], "NFT: Onna already linked");
            linkedOnnas[_linkedOnnaIds[i]] = true;
        }

        for (i = 0; i < _tokenIds.length; i++) {
            _totalSupply.increment();
            _mint(_to, _tokenIds[i]);
        }
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        require(!isMetadataLocked, "Operations: Contract is locked");
        baseURI = _uri;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function isTokenLinked(uint8 linkedCollection, uint256 tokenId) public view returns (bool) {
        if (linkedCollection == 0) return linkedSamurais[tokenId];
        return linkedOnnas[tokenId];
    }
}