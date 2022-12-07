// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Panda is ERC721, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // @dev Minter role
    bytes32 public constant MINTER = keccak256("MINTER");
    // @dev Owner role
    bytes32 public constant OWNER = DEFAULT_ADMIN_ROLE;

    // @dev Metadata base uri
    string public baseURI;

    /**
     * @notice Constructor
     * @param _name Collection name
     * @param _symbol Collection symbol
     * @param _baseURI Collection base uri
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        _tokenIdCounter.increment();

        _grantRole(OWNER, msg.sender);
        _grantRole(MINTER, msg.sender);
    }

    /**
     * @notice Mint nft
     * @param to Owner address
     */
    function safeMint(address to) external onlyRole(MINTER) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /**
     * @notice Add minter
     * @param minter New minter
     */
    function addMinter(address minter) external onlyRole(OWNER) {
        grantRole(MINTER, minter);
    }

    /**
     * @notice Add Owner
     * @param owner New owner
     */
    function addOwner(address owner) external onlyRole(OWNER) {
        grantRole(OWNER, owner);
    }

    /**
     * @notice Set base uri
     * @param _newBaseURI New base uri
     */
    function setBaseURI(string memory _newBaseURI) external onlyRole(OWNER) {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Revoke minter
     * @param minter Minter address
     */
    function revokeMinter(address minter) external onlyRole(OWNER) {
        revokeRole(MINTER, minter);
    }

    /**
     * @notice Get base uri
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}