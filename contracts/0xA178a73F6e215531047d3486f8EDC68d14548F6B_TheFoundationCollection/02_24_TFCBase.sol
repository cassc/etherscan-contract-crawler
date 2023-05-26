// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';
import '@nftculture/nftc-open-contracts/contracts/utility/AuxHelper16.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';
import '@nftculture/nftc-contract-library/contracts/token/FourPhaseAlternateMint.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

// ERC721A from Chiru Labs
import 'erc721a/contracts/ERC721A.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Error Codes
error ExceedsMaxSupply();
error ExceedsAvailablePresaleMints();
error ExceedsAvailablePublicMints();
error ProofInvalidPresale();

/**
 * @title TFCBase
 * @author @NiftyMike, NFT Culture
 * @dev Standard ERC721a Implementation
 *
 * Visit the NFTC Labs open source repo on github:
 * https://github.com/NFTCulture/nftc-open-contracts
 */
abstract contract TFCBase is
    ERC721A,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    FourPhaseAlternateMint,
    MerkleLeaves,
    AuxHelper16
{
    using Strings for uint256;
    using MerkleClaimList for MerkleClaimList.Root;

    // immutable for unit testing
    uint256 private immutable MAX_NFTS_FOR_PRESALE_1AND2;
    uint256 private immutable MAX_NFTS_FOR_PRESALE_3;
    uint256 private immutable MAX_NFTS_FOR_SALE;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;
    uint256 private constant MAX_PRESALE_BATCH_SIZE = 50;
    uint256 private constant MAX_PUBLIC_BATCH_SIZE = 20;

    string public baseURI;

    MerkleClaimList.Root private _presale1Root;
    MerkleClaimList.Root private _presale2Root;
    MerkleClaimList.Root private _presale3Root;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits,
        uint256 __maxNftsForPresale1and2,
        uint256 __maxNftsForPresale3,
        uint256 __maxNftsForSale,
        uint256 __discountPrice,
        uint256 __fullPrice
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        FourPhaseAlternateMint(__discountPrice, __fullPrice, __fullPrice, __fullPrice)
    {
        baseURI = __baseURI;

        MAX_NFTS_FOR_PRESALE_1AND2 = __maxNftsForPresale1and2;
        MAX_NFTS_FOR_PRESALE_3 = __maxNftsForPresale3;
        MAX_NFTS_FOR_SALE = __maxNftsForSale;
    }

    function maxPresale1and2() external view returns (uint256) {
        return MAX_NFTS_FOR_PRESALE_1AND2;
    }

    function maxPresale3() external view returns (uint256) {
        return MAX_NFTS_FOR_PRESALE_3;
    }

    function maxSupply() external view returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function presaleBatchSize() external pure returns (uint256) {
        return MAX_PRESALE_BATCH_SIZE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return MAX_PUBLIC_BATCH_SIZE;
    }

    function isOpenEdition() external pure returns (bool) {
        return false;
    }

    function auxMintValues(address wallet)
        external
        view
        returns (
            uint16 presale1Purchases,
            uint16 presale2Purchases,
            uint16 presale3Purchases,
            uint32 publicMintPurchases
        )
    {
        // Unpack single value from _getAux() to determine presale 1-3 and publicMint purchases
        return _unpack16(_getAux(wallet));
    }

    function getPresale1TokensPurchased(address wallet) external view returns (uint32) {
        (uint32 presale1Purchases, , , ) = _unpack16(_getAux(wallet));
        return presale1Purchases;
    }

    function getPresale2TokensPurchased(address wallet) external view returns (uint32) {
        (, uint32 presale2Purchases, , ) = _unpack16(_getAux(wallet));
        return presale2Purchases;
    }

    function getPresale3TokensPurchased(address wallet) external view returns (uint32) {
        (, , uint32 presale3Purchases, ) = _unpack16(_getAux(wallet));
        return presale3Purchases;
    }

    function getPublicMintTokensPurchased(address wallet) external view returns (uint32) {
        (, , , uint32 publicMintPurchases) = _unpack16(_getAux(wallet));
        return publicMintPurchases;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setMerkleRoots(
        bytes32 __presale1Root,
        bytes32 __presale2Root,
        bytes32 __presale3Root
    ) external onlyOwner {
        if (__presale1Root != 0) {
            _presale1Root._setRoot(__presale1Root);
        }

        if (__presale2Root != 0) {
            _presale2Root._setRoot(__presale2Root);
        }

        if (__presale3Root != 0) {
            _presale3Root._setRoot(__presale3Root);
        }
    }

    function checkPresale1(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _presale1Root._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextPresale1Index(address wallet) external view returns (uint256) {
        (uint32 presale1Purchases, , , ) = _unpack16(_getAux(wallet));
        return presale1Purchases;
    }

    function checkPresale2(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _presale2Root._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextPresale2Index(address wallet) external view returns (uint256) {
        (, uint32 presale2Purchases, , ) = _unpack16(_getAux(wallet));
        return presale2Purchases;
    }

    function checkPresale3(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _presale3Root._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextPresale3Index(address wallet) external view returns (uint256) {
        (, , uint32 presale3Purchases, ) = _unpack16(_getAux(wallet));
        return presale3Purchases;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        return string(abi.encodePacked(base, _tokenFilename(tokenId)));
    }

    /**
     * @notice Owner: reserve tokens for team.
     *
     * @param friends addresses to send tokens  to.
     * @param count the number of tokens to mint.
     *
     * Note: Marked payable, to enable pre-validation of contract payments function with a tiny amount of eth.
     */
    function reserveTokens(address[] memory friends, uint256 count) external payable onlyOwner {
        require(0 < count && count <= MAX_RESERVE_BATCH_SIZE, 'Invalid count');

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalPublicMintTokens(friends[idx], count);
        }
    }

    /**
     * @notice Presale tokens Phase 1 - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     */
    function presalePhaseOneTokens(bytes32[] calldata proof, uint256 count)
        external
        payable
        nonReentrant
        onlyUsers
        isPresale1
    {
        require(0 < count && count <= MAX_PRESALE_BATCH_SIZE, 'Invalid count');
        require(msg.value == presale1PricePerNft * count, 'Invalid price');

        (
            uint16 presale1Purchases,
            uint16 presale2Purchases,
            uint16 presale3Purchases,
            uint16 publicMintPurchases
        ) = _unpack16(_getAux(msg.sender));

        uint256 newBalance = presale1Purchases + count;

        _setAux(
            msg.sender,
            _pack16(uint16(newBalance), presale2Purchases, presale3Purchases, publicMintPurchases)
        );

        _presale1Tokens(msg.sender, proof, newBalance, count);
    }

    /**
     * @notice Presale tokens Phase 2 - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     */
    function presalePhaseTwoTokens(bytes32[] calldata proof, uint256 count)
        external
        payable
        nonReentrant
        onlyUsers
        isPresale2
    {
        require(0 < count && count <= MAX_PRESALE_BATCH_SIZE, 'Invalid count');
        require(msg.value == presale2PricePerNft * count, 'Invalid price');

        (
            uint16 presale1Purchases,
            uint16 presale2Purchases,
            uint16 presale3Purchases,
            uint16 publicMintPurchases
        ) = _unpack16(_getAux(msg.sender));

        uint256 newBalance = presale2Purchases + count;

        _presale2Tokens(msg.sender, proof, newBalance, count);

        _setAux(
            msg.sender,
            _pack16(presale1Purchases, uint16(newBalance), presale3Purchases, publicMintPurchases)
        );
    }

    /**
     * @notice Presale tokens Phase 3 - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     */
    function presalePhaseThreeTokens(bytes32[] calldata proof, uint256 count)
        external
        payable
        nonReentrant
        onlyUsers
        isPresale3
    {
        require(0 < count && count <= MAX_PRESALE_BATCH_SIZE, 'Invalid count');
        require(msg.value == presale3PricePerNft * count, 'Invalid price');

        (
            uint16 presale1Purchases,
            uint16 presale2Purchases,
            uint16 presale3Purchases,
            uint16 publicMintPurchases
        ) = _unpack16(_getAux(msg.sender));

        uint256 newBalance = presale3Purchases + count;

        _presale3Tokens(msg.sender, proof, newBalance, count);

        _setAux(
            msg.sender,
            _pack16(presale1Purchases, presale2Purchases, uint16(newBalance), publicMintPurchases)
        );
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     *
     * @param count the number of tokens to mint.
     */
    function mintTokens(uint256 count) external payable nonReentrant onlyUsers isPublicMinting {
        require(0 < count && count <= MAX_PUBLIC_BATCH_SIZE, 'Invalid count');
        require(msg.value == publicMintPricePerNft * count, 'Invalid price');

        _internalPublicMintTokens(_msgSender(), count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal view virtual returns (string memory) {
        return tokenId.toString();
    }

    function _presale1Tokens(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count
    ) internal {
        // Verify proof matches expected target total number of presale mints.
        if (!_presale1Root._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1)))
            //Zero-based index.
            revert ProofInvalidPresale();

        _internalPresaleTokens1and2(minter, count);
    }

    function _presale2Tokens(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count
    ) internal {
        // Verify proof matches expected target total number of presale mints.
        if (!_presale2Root._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1)))
            //Zero-based index.
            revert ProofInvalidPresale();

        _internalPresaleTokens1and2(minter, count);
    }

    function _presale3Tokens(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count
    ) internal {
        // Verify proof matches expected target total number of presale mints.
        if (!_presale3Root._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1)))
            //Zero-based index.
            revert ProofInvalidPresale();

        _internalPresaleTokens3(minter, count);
    }

    function _internalPresaleTokens1and2(address minter, uint256 count) internal {
        if (_totalMinted() + count > MAX_NFTS_FOR_PRESALE_1AND2) revert ExceedsMaxSupply();

        _safeMint(minter, count);
    }

    function _internalPresaleTokens3(address minter, uint256 count) internal {
        if (_totalMinted() + count > MAX_NFTS_FOR_PRESALE_3) revert ExceedsMaxSupply();

        _safeMint(minter, count);
    }

    function _internalPublicMintTokens(address minter, uint256 count) internal {
        if (_totalMinted() + count > MAX_NFTS_FOR_SALE) revert ExceedsMaxSupply();

        _safeMint(minter, count);
    }
}