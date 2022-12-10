// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

import "../lib/ERC721.sol";
import "../lib/ERC721Enumerable.sol";
import "../lib/MetaOwnable.sol";
import "../lib/Mintable.sol";
import "../lib/ClaimContext.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/** @title Standard ERC721 NFT Contract with support of
 * 1. Meta transactions (owner as signer, user as executor).
 * 2. Contextual claim (List of tokens for a wallet against identifier)
 * 3. Minter (has the minting rights, different from owner)
 *
 * @author NitroLeague.
 */
contract Season0Cars is ERC721Enumerable, MetaOwnable, Mintable, ClaimContext {
    string private baseURI;
    uint256 public maxTokenTypes;
    mapping(uint256 => uint256) public nextTokenIdByType;

    event BaseURIChanged(
        string indexed oldBaserURI,
        string indexed newBaserURI
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _forwarder,
        address minter,
        uint256 dailyLimit,
        uint256 _maxTokenTypes
    ) ERC721(_name, _symbol, _forwarder) Mintable(dailyLimit) {
        setMinter(minter);
        unPauseMint();
        _transferOwnership(_msgSender());
        require(_maxTokenTypes > 0, "invalid max token type set");
        maxTokenTypes = _maxTokenTypes;
        for (uint256 i = 0; i < maxTokenTypes; i++) nextTokenIdByType[i] = i;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        require(bytes(_baseURI).length > 0, "baseURI cannot be empty");
        emit BaseURIChanged(baseURI, _baseURI);
        baseURI = _baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function bulkMint(
        address[] calldata _to,
        uint256[] calldata _tokenTypes
    ) public onlyOwner {
        require(_to.length == _tokenTypes.length, "Array length mismatch");
        for (uint256 i = 0; i < _to.length; i++) {
            _mintToken(_to[i], _tokenTypes[i]);
        }
    }

    function safeMint(address _to, uint256 _tokenType) public onlyOwner {
        _mintToken(_to, _tokenType);
    }

    function getNextTokenIdForType(
        uint256 tokenType
    ) internal view returns (uint256) {
        require(tokenType < maxTokenTypes, "Invalid token type");
        return nextTokenIdByType[tokenType];
    }

    function safeMintGame(
        string memory _context,
        address _to,
        uint256 tokenType
    ) public onlyMinter mintingAllowed inLimit validClaim(_context, _to) {
        setContext(_context, _to);
        _incrementMintCounter();
        _mintToken(_to, tokenType);
    }

    function _mintToken(address _to, uint256 tokenType) internal {
        require(tokenType < maxTokenTypes, "Invalid token type");
        uint256 tokenId = nextTokenIdByType[tokenType];
        nextTokenIdByType[tokenType] += maxTokenTypes;
        _safeMint(_to, tokenId);
    }
}