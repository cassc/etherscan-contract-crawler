// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './nftc-open-contracts/whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from './nftc-open-contracts/whitelisting/MerkleClaimList.sol';
import {WalletIndex} from './nftc-open-contracts/whitelisting/WalletIndex.sol';

// ERC721A from Chiru Labs
import './ERC721A.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title GPunksBase
 * @author kodbilen.eth | twitter.com/kodbilenadam
 * @dev Standard ERC721A implementation 
 *
 * GobzPunksBase is an ERC721A NFT contract to allow free mint for the GEN1 and GEN2 in GobzNFT community.
 *
 * In addition to using ERC721A, gas is optimized via Merkle Trees and use of constants where possible.
 *
 * Reusable functionality is packaged in included contracts:
 *      - MerkleLeaves - helper functionality for MerkleTrees
 *
 * And libraries:
 *      - MerkleClaimList - a self contained basic MerkleTree implementation, that makes it easier
 *          to support multiple merkle trees in the same contract.
 *      - WalletIndex - a helper library for tracking indexes by wallet
 *
 * Based on NoobPunksContract by NiftyMike.eth & NFTCulture
 * NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
 *
 */
abstract contract GPunksBase is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    MerkleLeaves
{
    using Strings for uint256;
    using MerkleClaimList for MerkleClaimList.Root;
    using WalletIndex for WalletIndex.Index;


    uint256 private constant MAX_NFTS_FOR_SALE = 1500;
    uint256 private constant MAX_CLAIM_BATCH_SIZE = 10; 

    bool public IS_CLAIM_ACTIVE = false;

    string public baseURI;

    MerkleClaimList.Root private _claimRoot;

    WalletIndex.Index private _claimedWalletIndexes;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI
    ) ERC721A(__name, __symbol) {
        baseURI = __baseURI;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setMerkleRoot(bytes32 __claimRoot) external onlyOwner {
            _claimRoot._setRoot(__claimRoot);

    }

    function toggleClaim() public 
    onlyOwner 
    {
        IS_CLAIM_ACTIVE = !IS_CLAIM_ACTIVE;
    }
    function checkClaim(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _claimRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function totalMintedByWallet(address wallet) external view returns (uint256) {
        return _numberMinted(wallet);
    }

    function getNextClaimIndex(address wallet) external view returns (uint256) {
        return _claimedWalletIndexes._getNextIndex(wallet);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        return string(abi.encodePacked(base, _tokenFilename(tokenId)));
    }

    function reservePunks(address[] memory friends, uint256 count) external onlyOwner {

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], count);
        }
    }



    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal view virtual returns (string memory) {
        return tokenId.toString();
    }

    function claimPunks(bytes32[] calldata proof, uint256 count) external nonReentrant {
        require(0 < count && count <= MAX_CLAIM_BATCH_SIZE, 'Invalid count');
        require(IS_CLAIM_ACTIVE, "Sale haven't started");
        _claimPunks(_msgSender(), proof, count);
}


    function _claimPunks(
    address minter,
    bytes32[] calldata proof,
    uint256 count
) internal {
    // Verify address is eligible for claim.
    require(_claimRoot._checkLeaf(proof, _generateLeaf(minter)), 'Proof invalid for claim');

    // Has to be tracked indepedently for claim, since caller might have previously used claim.
    require(
        _claimedWalletIndexes._getNextIndex(minter) + count <= MAX_CLAIM_BATCH_SIZE,
        'Requesting too many in claim'
    );
    _claimedWalletIndexes._incrementIndex(minter, count);

    _internalMintTokens(minter, count);
}


    function _internalMintTokens(address minter, uint256 count) internal {
        require(totalSupply() + count <= MAX_NFTS_FOR_SALE, 'Limit exceeded');

        _safeMint(minter, count);
    }
}