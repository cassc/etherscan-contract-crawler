// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Nft is ERC721, ERC721Enumerable, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    struct NftInfo {
        uint256 lvl;
    }

    mapping(uint256 => NftInfo) private nftInfo;

    event NftUpgradedEvent();
    event BaseURIUpdatedEvent(string _baseURI);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADE_ROLE, msg.sender);

        setBaseURI(_baseURI);
    }

    function nftInfoOf(uint256 _tokenId) external view returns (bool, address, NftInfo memory) {
        return (
        _exists(_tokenId),
        _ownerOf(_tokenId),
        nftInfo[_tokenId]
        );
    }

    function upgradeNft(uint256 _tokenId, uint256 _lvl, uint256[] memory _burn) external {

    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), "/", nftInfo[_tokenId].lvl)) : "";
    }

    function safeMint(address _to, uint256 _lvl) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);

        nftInfo[tokenId].lvl = _lvl;
    }

    /*function burn(uint256 tokenId) public override {
        super.burn(tokenId);
    }*/

    function setBaseURI(string memory _baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;

        emit BaseURIUpdatedEvent(_baseURI);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId, uint256 _batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}