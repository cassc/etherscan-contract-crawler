// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from '@nftculture/nftc-open-contracts/contracts/utility/BooleanPacking.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';
import {WalletIndex} from '@nftculture/nftc-contract-library/contracts/whitelisting/WalletIndex.sol';

// ERC721A from Chiru Labs
import 'erc721a/contracts/ERC721A.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';

/**
 * @title NoobPunksBase
 * @author @NiftyMike, NFT Culture
 * @dev Standard ERC721A implementation
 *
 * NoobPunksBase is a straightforward ERC721A NFT contract, with both a claiming
 * phase (free tokens) and a presale phase (paid tokens).
 *
 * In addition to using ERC721A, gas is optimized via Merkle Trees, boolean packing
 * and use of constants where possible.
 *
 * Reusable functionality is packaged in included contracts:
 *      - GuardedAgainstContracts - an attempt to limit access to functions to user transactions
 *      - LockedPaymentSplitter - an reduced sized version of PaymentSplitter, with better access
 *          controls
 *      - MerkleLeaves - helper functionality for MerkleTrees
 *
 * And libraries:
 *      - BooleanPacking - for boolean packing, obviously :)
 *      - MerkleClaimList - a self contained basic MerkleTree implementation, that makes it easier
 *          to support multiple merkle trees in the same contract.
 *      - WalletIndex - a helper library for tracking indexes by wallet
 *
 * Visit the NFTC Labs open source repo on github:
 * https://github.com/NFTCulture/nftc-open-contracts
 *
 * Pieces not available in the github are pre-release and will be added as time allows.
 */
abstract contract NoobPunksBase is
    ERC721A,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    MerkleLeaves
{
    using Strings for uint256;
    using BooleanPacking for uint256;
    using MerkleClaimList for MerkleClaimList.Root;
    using WalletIndex for WalletIndex.Index;

    uint256 private constant MAX_NFTS_FOR_SALE = 10000;
    uint256 private constant MAX_CLAIM_BATCH_SIZE = 50;
    uint256 private constant MAX_MINT_BATCH_SIZE = 20;
    uint256 private constant PRESALE_QUANTITY = 2;

    uint256 private constant CLAIMING_PHASE = 1;
    uint256 private constant PRESALE_PHASE = 2;
    uint256 private constant MINTING_PHASE = 3;

    uint256 public claimPricePerNft;
    uint256 public presalePricePerNft;
    uint256 public mintPricePerNft;

    string public baseURI;

    // BooleanPacking used on mintControlFlags
    uint256 private mintControlFlags;

    MerkleClaimList.Root private _claimRoot;
    MerkleClaimList.Root private _presaleRoot;

    WalletIndex.Index private _presaleWalletIndexes;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits
    ) ERC721A(__name, __symbol) SlimPaymentSplitter(__addresses, __splits) {
        baseURI = __baseURI;

        presalePricePerNft = 0.04 ether;
        mintPricePerNft = 0.04 ether;
    }

    function setMintingState(
        bool __claimingActive,
        bool __presaleActive,
        bool __mintingActive,
        uint256 __claimPricePerNft,
        uint256 __presalePricePerNft,
        uint256 __mintPricePerNft
    ) external onlyOwner {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(CLAIMING_PHASE, __claimingActive);
        tempControlFlags = tempControlFlags.setBoolean(PRESALE_PHASE, __presaleActive);
        tempControlFlags = tempControlFlags.setBoolean(MINTING_PHASE, __mintingActive);

        mintControlFlags = tempControlFlags;

        if (__claimPricePerNft > 0) {
            claimPricePerNft = __claimPricePerNft;
        }

        if (__presalePricePerNft > 0) {
            presalePricePerNft = __presalePricePerNft;
        }

        if (__mintPricePerNft > 0) {
            mintPricePerNft = __mintPricePerNft;
        }
    }

    function isClaimingActive() external view returns (bool) {
        return mintControlFlags.getBoolean(CLAIMING_PHASE);
    }

    function isPresaleActive() external view returns (bool) {
        return mintControlFlags.getBoolean(PRESALE_PHASE);
    }

    function isMintingActive() external view returns (bool) {
        return mintControlFlags.getBoolean(MINTING_PHASE);
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setMerkleRoots(bytes32 __claimRoot, bytes32 __presaleRoot) external onlyOwner {
        if (__claimRoot != 0) {
            _claimRoot._setRoot(__claimRoot);
        }

        if (__claimRoot != 0) {
            _presaleRoot._setRoot(__presaleRoot);
        }
    }

    function checkClaim(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _claimRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextClaimIndex(address wallet) external view returns (uint256) {
        return _numberMinted(wallet);
    }

    function checkPresale(bytes32[] calldata proof, address wallet) external view returns (bool) {
        return _presaleRoot._checkLeaf(proof, _generateLeaf(wallet));
    }

    function getNextPresaleIndex(address wallet) external view returns (uint256) {
        return _presaleWalletIndexes._getNextIndex(wallet);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        return string(abi.encodePacked(base, _tokenFilename(tokenId)));
    }

    /**
     * @notice Owner: reserve NoobPunks for team.
     *
     * @param friends addresses to send NoobPunks to.
     * @param count the number of NoobPunks to mint.
     */
    function reservePunks(address[] memory friends, uint256 count) external onlyOwner {
        require(0 < count && count <= MAX_CLAIM_BATCH_SIZE, 'Invalid count');

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], count);
        }
    }

    function claimPunks(bytes32[] calldata proof, uint256 count) external payable nonReentrant {
        require(mintControlFlags.getBoolean(CLAIMING_PHASE), 'Claiming stopped');
        require(0 < count && count <= MAX_CLAIM_BATCH_SIZE, 'Invalid count');
        require(msg.value >= claimPricePerNft * count, 'Invalid price');

        _claimPunks(_msgSender(), proof, count);
    }

    function presalePunks(bytes32[] calldata proof, uint256 count) external payable nonReentrant {
        require(mintControlFlags.getBoolean(PRESALE_PHASE), 'Presale stopped');
        require(0 < count && count <= PRESALE_QUANTITY, 'Invalid count');
        require(msg.value >= presalePricePerNft * count, 'Invalid price');

        _presalePunks(_msgSender(), proof, count);
    }

    /**
     * @notice Mint NoobPunks - purchase bound by terms & conditions of project.
     *
     * @param count the number of NoobPunks to mint.
     */
    function mintPunks(uint256 count) external payable nonReentrant onlyUsers {
        require(mintControlFlags.getBoolean(MINTING_PHASE), 'Minting stopped');
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');
        require(mintPricePerNft * count == msg.value, 'Invalid price');

        _internalMintTokens(_msgSender(), count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal view virtual returns (string memory) {
        return tokenId.toString();
    }

    function _claimPunks(
        address minter,
        bytes32[] calldata proof,
        uint256 count
    ) internal {
        // Verify proof matches expected target total number of claims.
        require(
            _claimRoot._checkLeaf(
                proof,
                _generateIndexedLeaf(minter, (_numberMinted(minter) + count) - 1) //Zero-based index.
            ),
            'Proof invalid for claim'
        );

        _internalMintTokens(minter, count);
    }

    function _presalePunks(
        address minter,
        bytes32[] calldata proof,
        uint256 count
    ) internal {
        // Verify address is eligible for presale mints.
        require(_presaleRoot._checkLeaf(proof, _generateLeaf(minter)), 'Proof invalid for presale');

        // Has to be tracked indepedently for presale, since caller might have previously used claims.
        require(
            _presaleWalletIndexes._getNextIndex(minter) + count <= PRESALE_QUANTITY,
            'Requesting too many in presale'
        );
        _presaleWalletIndexes._incrementIndex(minter, count);

        _internalMintTokens(minter, count);
    }

    function _internalMintTokens(address minter, uint256 count) internal {
        require(totalSupply() + count <= MAX_NFTS_FOR_SALE, 'Limit exceeded');

        _safeMint(minter, count);
    }
}