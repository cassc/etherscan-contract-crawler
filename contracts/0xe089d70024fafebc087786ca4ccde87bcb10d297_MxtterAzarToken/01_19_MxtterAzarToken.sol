// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/**
 *  __    __     __  __     ______   ______   ______     ______
 * /\ "-./  \   /\_\_\_\   /\__  _\ /\__  _\ /\  ___\   /\  == \
 * \ \ \-./\ \  \/_/\_\/_  \/_/\ \/ \/_/\ \/ \ \  __\   \ \  __<
 *  \ \_\ \ \_\   /\_\/\_\    \ \_\    \ \_\  \ \_____\  \ \_\ \_\
 *   \/_/  \/_/   \/_/\/_/     \/_/     \/_/   \/_____/   \/_/ /_/
 *
 * @title Token contract for Mxtter Azar public sale pieces
 * @dev This contract allows the distribution of Mxtter Azar public sale tokens
 *
 *
 * MXTTER X BLOCK::BLOCK
 *
 * Smart contract work done by joshpeters.eth
 */

contract MxtterAzarToken is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    PaymentSplitter,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bool public isPresaleActive;
    bool public isMintActive;
    uint256 public immutable mintPrice;

    // Merkle tree root
    bytes32 public root;

    // Tracks hash for each token
    mapping(uint256 => bytes32) private hashForToken;

    // Base URI
    string private uri;

    event NewToken(uint256 indexed tokenId, bytes32 tokenHash);

    constructor(
        uint256 _mintPrice,
        uint256 _tokenOffset,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721("MxtterAzarToken", "MXTTER") PaymentSplitter(_payees, _shares) {
        mintPrice = _mintPrice;
        uri = _uri;
        isPresaleActive = false;
        isMintActive = false;

        // update count to offset
        for(uint256 i = 0; i < _tokenOffset; i += 1) {
            _tokenIdCounter.increment();
        }
    }

    // @dev Presale minting function. Mints token to sender.
    // @param proof Merkel tree proof
    function presaleMint(bytes32[] calldata proof) public payable {
        require(isPresaleActive, "Presale Not Active");
        require(mintPrice == msg.value, "Incorrect Value");
        require(
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Caller not whitelisted"
        );

        _mintToken(msg.sender);
    }

    // @dev Returns if an address is whitelisted for presale
    // @param proof Merkel tree proof
    // @param _address Address to check
    function isEligiblePresale(bytes32[] calldata proof, address _address)
        external
        view
        returns (bool)
    {
        if (
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(_address))
            )
        ) {
            return true;
        }
        return false;
    }

    // @dev Main minting function. Mints token to sender.
    function mint() public payable {
        require(isMintActive, "Mint Not Active");
        require(mintPrice == msg.value, "Incorrect Value");

        _mintToken(msg.sender);
    }

    // @dev Gets a hash for a specific token
    // @param tokenId Token ID to get hash for
    // @return the hash
    function getTokenHash(uint256 tokenId) public view returns (bytes32) {
        return hashForToken[tokenId];
    }

    // @dev Flips the ability to mint new tokens for presale
    function flipPresaleState() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    // @dev Flips the ability to mint new tokens for main sale
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }

    // @dev Allows to set the baseURI dynamically
    // @param uri The base uri for the metadata store
    function setBaseURI(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    // @dev Private minting function for artist
    function mintToken(uint256 numberOfTokens, address to) external onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintToken(to);
        }
    }

    function _mintToken(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        bytes32 tokenHash = _getHash(tokenId);
        hashForToken[tokenId] = tokenHash;
        emit NewToken(tokenId, tokenHash);
    }

    function _getHash(uint256 tokenId) private view returns (bytes32) {
        return
            keccak256(abi.encodePacked(tokenId, blockhash(block.number - 1)));
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}