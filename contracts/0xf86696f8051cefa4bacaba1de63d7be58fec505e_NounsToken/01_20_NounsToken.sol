// SPDX-License-Identifier: GPL-3.0

/// @title The BeachBum ERC-721 token

// NounsToken.sol modifies Nouns NounsToken.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/076cd753307632ce8efeb65a07f1bd797a5ecb4d/packages/nouns-contracts/contracts/NounsToken.sol
//
// MODIFICATIONS:
// Stripped of all DAO-related functionality, added Merkle Drop, public mint, and royalty.

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';

contract NounsToken is INounsToken, Ownable, ERC721Enumerable {
    // An address who has admin permissions
    address public admin;

    // Mint fee
    uint256 public mintFee;

    // Royalty basis
    uint256 public royaltyBasis;

    // Max supply
    uint256 public immutable maxSupply;

    // Merkle root
    bytes32 public root;

    // Number of accounts in merkle drop
    uint256 public merkleQuantity;

    // Claims from merkle drop
    mapping(address => bool) merkleClaims;

    // The Nouns token URI descriptor
    INounsDescriptor public descriptor;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // Whether the admin can be updated
    bool public isAdminLocked;

    // Whether the public mint is enabled
    bool public isMintEnabled;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // The internal noun ID tracker
    uint256 private _currentNounId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'bafkreia6f76hnnnmnjdawhelgy7sojfr6bcctd5cy6bsnlnsq777tviedi';

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /**
     * @notice Require that the sender is the admin.
     */
    modifier onlyAdminOrOwner() {
        require(
            ((msg.sender == admin) && !isAdminLocked) || (msg.sender == owner()),
            'Sender is not the owner or admin'
        );
        _;
    }

    /**
     * @notice Require that the mint is enabled
     */
    modifier mintEnabled() {
        require(isMintEnabled, 'Mint is disabled');
        _;
    }

    constructor(
        address _admin,
        uint256 _mintFee,
        uint256 _royaltyBasis,
        uint256 _maxSupply,
        bytes32 _root,
        uint256 _merkleQuantity,
        INounsDescriptor _descriptor,
        INounsSeeder _seeder,
        IProxyRegistry _proxyRegistry
    ) ERC721('BeachBums', 'BUMS') {
        admin = _admin;
        mintFee = _mintFee;
        royaltyBasis = _royaltyBasis;
        maxSupply = _maxSupply;
        root = _root;
        merkleQuantity = _merkleQuantity;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = _proxyRegistry;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), ((salePrice * royaltyBasis) / 10000));
    }

    /**
     * @notice Withdraw balance of contract to owner
     */
    function withdraw() external override onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Withdraw ERC20 balance of contract to owner
     */
    function withdrawERC20Balance(address erc20ContractAddress) external override onlyOwner {
        IERC20(erc20ContractAddress).transfer(owner(), IERC20(erc20ContractAddress).balanceOf(address(this)));
    }

    /**
     * @notice Mint a Noun to address
     * @dev Call _mintTo with the to address(es).
     */
    function mint(address account) public payable override mintEnabled returns (uint256) {
        require(msg.value >= mintFee, 'Insufficient mint fee');
        require(_currentNounId + merkleQuantity < maxSupply, 'Max supply reached');
        return _mintTo(account, _currentNounId++);
    }

    /**
     * @notice Mint multiple Nouns to address
     * @dev Call _mintTo with the to address(es).
     */
    function mintBatch(address account, uint256 quantity)
        public
        payable
        override
        mintEnabled
        returns (uint256, uint256)
    {
        require(msg.value >= mintFee * quantity, 'Insufficient mint fee');
        require(_currentNounId + quantity + merkleQuantity < maxSupply, 'Max supply reached');
        uint256 startId = _currentNounId;
        for (uint256 i = 0; i < quantity; i++) {
            _mintTo(account, _currentNounId++);
        }
        return (startId, _currentNounId - 1);
    }

    /**
     * @notice Mint a Noun to address in merkle drop
     */
    function redeem(address account, bytes32[] calldata proof) public override returns (uint256) {
        require(_verify(_leaf(account), proof), 'Invalid proof');
        require(_currentNounId < maxSupply, 'Max supply reached');
        require(!merkleClaims[account], 'Already claimed');
        merkleClaims[account] = true;
        return _mintTo(account, _currentNounId++);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set merkle root
     * @dev Only callable by admin or owner
     */
    function setRoot(bytes32 merkleRoot, uint256 quantity) external override onlyAdminOrOwner {
        root = merkleRoot;
        merkleQuantity = quantity;
    }

    /**
     * @notice Set mint fee
     * @dev Only callable by admin or owner
     */
    function setMintFee(uint256 fee) external override onlyAdminOrOwner {
        mintFee = fee;
    }

    /**
     * @notice Set mint fee
     * @dev Only callable by admin or owner
     */
    function toggleMint() external override onlyAdminOrOwner {
        isMintEnabled = !isMintEnabled;
    }

    /**
     * @notice Set royalty basis
     * @dev Only callable by admin or owner
     */
    function setRoyalty(uint256 _royaltyBasis) external override onlyAdminOrOwner {
        require(_royaltyBasis <= 10000, 'Royalty cannot exceed 100%');
        royaltyBasis = _royaltyBasis;
    }

    /**
     * @notice Set the token admin.
     * @dev Only callable by the owner when not locked.
     */
    function setAdmin(address _admin) external override onlyOwner {
        admin = _admin;

        emit AdminUpdated(_admin);
    }

    /**
     * @notice Lock the admin.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockAdmin() external override onlyOwner {
        isAdminLocked = true;

        emit AdminLocked();
    }

    /**
     * @notice Mint a BeachBum with `nounId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 nounId) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(nounId, descriptor);

        _safeMint(to, nounId);
        emit BeachBumCreated(nounId, seed);

        return nounId;
    }
}