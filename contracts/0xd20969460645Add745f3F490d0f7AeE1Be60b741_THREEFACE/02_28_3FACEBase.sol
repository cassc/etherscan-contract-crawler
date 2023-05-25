// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';
import '@nftculture/nftc-open-contracts/contracts/utility/AuxHelper32.sol';
import './AuxHelperFourInto256.sol';
import './DigiSigHelper.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/token/phased/PhasedMintThree.sol';
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

// ERC721A from Chiru Labs
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// Error Codes
error ExceedsMaxSupply();
error ExceedsReserveBatchSize();
error ProofInvalidPresale();
error ExceedsPresaleBatchSize();
error InvalidPresalePayment();
error ExceedsPresalePurchaseLimit();
error ExceedsPresaleSupply();
error ExceedsPublicMintBatchSize();
error InvalidPublicMintPayment();
error BindingNotAllowed();
error InvalidSelectedNature();
error InvalidRemoteMinter();

/**
 * @title THREEFACEBase
 * @author @NiftyMike | @NFTCulture
 * @dev ERC721a Burnable, Queryable with @NFTCulture standardized components.
 *
 * Three phase mint:
 * Phase One - Indexed Allowlist
 * Phase Two - Indexed Allowlist
 * Phase Three - Public
 *
 * Contract features a concept called "Binding" where the user can trigger a new
 * generative artwork to take the place of a token's current artwork.
 */
abstract contract THREEFACEBase is
    ERC721ABurnable,
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    LockedPaymentSplitter,
    PhasedMintThree,
    MerkleLeaves,
    AuxHelperFourInto256,
    AuxHelper32,
    DigiSigHelper
{
    using Strings for uint256;
    using BooleanPacking for uint256;
    using MerkleClaimList for MerkleClaimList.Root;

    uint256 private constant MAX_NFTS_FOR_PRESALE_1 = 1896;
    uint256 private constant MAX_NFTS_FOR_SALE = 4096;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 32;
    uint256 private constant MAX_MINT_BATCH_SIZE = 10;

    uint256 public constant NATURE_BASE_VAL = 100;
    uint256 public constant NATURE_MIN = 0;
    uint256 public constant NATURE_MAX = 3;

    // Control flags for the token binding process.
    uint256 private constant BINDING_ALLOWED = 5;
    uint256 private constant REFUNDING_ENABLED = 6;
    uint256 internal _bindingControlFlags;
    uint256 public bindingRefundAmount;

    string public baseURI;

    MerkleClaimList.Root private _phaseOneRoot;
    MerkleClaimList.Root private _phaseTwoRoot;

    // Nature URI fragments. NatureID -> NatureURI mapping.
    mapping(uint256 => string) internal _natureUriFragments;

    // User URI fragments. TokenID -> UserURI mapping.
    // Each IPFS Hash costs about 85k gas to store.
    // There are optimizations for this, but they reduce
    // user-friendliness and forward compatiblity.
    mapping(uint256 => string) internal _userUriFragments;

    struct TokenBindingData {
        uint64 tokenId;
        uint64 generation;
        uint64 isBoundToUser;
        uint64 reserved;
    }

    mapping(uint256 => TokenBindingData) internal _tokenBindingMap;

    // Use the event log for persistence of previous URI fragments.
    // This saves about 60k gas vs. saving them in the contract.
    event ReleaseURIFragment(uint256 tokenId, uint256 generation, string previousUriFragment);

    // Use the event log for tracking when tokens have been refunded.
    event TokenBindingRefunded(uint256 tokenId);

    address private _threefaceSigner;
    address private _remoteMinter;

    modifier canBind() {
        if (!_bindingControlFlags.getBoolean(BINDING_ALLOWED)) revert BindingNotAllowed();
        _;
    }

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits,
        uint256 __phaseOnePricePerNft,
        uint256 __phaseTwoPricePerNft,
        uint256 __phaseThreePricePerNft,
        uint256 __bindingRefundAmount
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        PhasedMintThree(__phaseOnePricePerNft, __phaseTwoPricePerNft, __phaseThreePricePerNft)
    {
        baseURI = __baseURI;

        _threefaceSigner = msg.sender;
        _remoteMinter = 0xdAb1a1854214684acE522439684a145E62505233;

        bindingRefundAmount = __bindingRefundAmount;
    }

    function maxPresaleOne() external pure returns (uint256) {
        return MAX_NFTS_FOR_PRESALE_1;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function phaseOneBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function phaseTwoBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function isOpenEdition() external pure returns (bool) {
        // Front end minting websites should treat this mint as an open edition, even though there is a hard cap.
        return false;
    }

    function isBindingAllowed() external view returns (bool) {
        return _isBindingAllowed();
    }

    function isRefundingEnabled() external view returns (bool) {
        return _isRefundingEnabled();
    }

    function setBindingState(
        bool __bindingAllowed,
        bool __refundingEnabled,
        uint256 __bindingRefundAmount
    ) external onlyOwner {
        uint256 tempControlFlags = _bindingControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(BINDING_ALLOWED, __bindingAllowed);
        tempControlFlags = tempControlFlags.setBoolean(REFUNDING_ENABLED, __refundingEnabled);

        _bindingControlFlags = tempControlFlags;

        if (__bindingRefundAmount > 0) {
            bindingRefundAmount = __bindingRefundAmount;
        }
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setThreefaceSigner(address __newSigner) external onlyOwner {
        _threefaceSigner = __newSigner;
    }

    function setRemoteMinter(address __newMinter) external onlyOwner {
        _remoteMinter = __newMinter;
    }

    function setNatureFragments(uint256[] memory __natureIds, string[] memory __natureUris) external onlyOwner {
        _setNatureFragments(__natureIds, __natureUris);
    }

    /**
     * @dev This is just here in case of emergency
     */
    function restoreUserFragment(
        uint256 tokenId,
        uint256 boundGenerationOverride,
        string calldata userUri,
        bool flush
    ) external onlyOwner {
        if (flush) {
            // Something bad must have happened, cause we are deliberately
            // wiping the bound state and generation here.
            delete _tokenBindingMap[tokenId];
        }

        // Do the normal workflow.
        _setBindToUser(tokenId, _tokenBindingMap[tokenId], userUri);

        if (flush) {
            _tokenBindingMap[tokenId].generation = uint64(boundGenerationOverride);
        }
    }

    /**
     * @dev This is just here in case of emergency
     */
    function restoreToBlank(uint256 tokenId, uint256 selectedNature) external onlyOwner {
        // Reset the fragment for this token.
        delete _tokenBindingMap[tokenId];

        // Make sure the ownership info is initialized.
        _initializeOwnershipAt(tokenId);

        // Override set the nature back to expected value.
        _setNature(tokenId, uint24(selectedNature));
    }

    function setMerkleRoots(bytes32 __phaseOneRoot, bytes32 __phaseTwoRoot) external onlyOwner {
        _setMerkleRoots(__phaseOneRoot, __phaseTwoRoot);
    }

    function _setMerkleRoots(bytes32 __phaseOneRoot, bytes32 __phaseTwoRoot) internal {
        if (__phaseOneRoot != 0) {
            _phaseOneRoot._setRoot(__phaseOneRoot);
        }

        if (__phaseTwoRoot != 0) {
            _phaseTwoRoot._setRoot(__phaseTwoRoot);
        }
    }

    function auxMintValues(address wallet)
        external
        view
        returns (uint32 presalePhaseOnePurchases, uint32 presalePhaseTwoPurchases)
    {
        // Unpack single value from _getAux() to determine presalePhaseOnePurchases and presalePhaseTwoPurchases
        return _unpack32(_getAux(wallet));
    }

    function checkProofPhaseOne(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextProofIndexPhaseOne(address wallet) external view returns (uint256) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getAux(wallet));
        return phaseOnePurchases;
    }

    function checkProofPhaseTwo(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextProofIndexPhaseTwo(address wallet) external view returns (uint256) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getAux(wallet));
        return phaseTwoPurchases;
    }

    function getPresalePhaseOneTokensPurchased(address wallet) external view returns (uint32) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getAux(wallet));
        return phaseOnePurchases;
    }

    function getPresalePhaseTwoTokensPurchased(address wallet) external view returns (uint32) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getAux(wallet));
        return phaseTwoPurchases;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        uint256 nature = _getNature(tokenId);

        if (!_isBoundToUser(tokenId)) {
            // Build uri for "blank" 3face.
            return string(abi.encodePacked(base, _natureUriFragments[nature], _tokenFilename(tokenId)));
        } else {
            // Note: these are direct IPFS links, and do not need the token id appended.
            return string(abi.encodePacked(base, _userUriFragments[tokenId]));
        }
    }

    function getNature(uint256 tokenId) external view returns (uint256) {
        return _getNature(tokenId);
    }

    function getBindingInfo(uint256 tokenId) external view returns (TokenBindingData memory) {
        return _tokenBindingMap[tokenId];
    }

    function getBindingInfo_CurrentFragment(uint256 tokenId) external view returns (string memory) {
        return _userUriFragments[tokenId];
    }

    function getBindingInfo_Generation(uint256 tokenId) external view returns (uint256) {
        return _tokenBindingMap[tokenId].generation;
    }

    function getBindingInfo_IsBoundToUser(uint256 tokenId) external view returns (bool) {
        return _tokenBindingMap[tokenId].isBoundToUser == 1;
    }

    function getBindingInfo_Status(uint256 tokenId, string calldata uriFragment) external view returns (uint256) {
        bytes32 theUriFragmentHash = keccak256(abi.encodePacked(uriFragment));

        if (keccak256(abi.encodePacked(_userUriFragments[tokenId])) == theUriFragmentHash) return 1;

        return 0;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Owner: reserve tokens for team.
     *
     * NOTE: All tokens in a given transaction will be forced to have the same nature.
     *
     * @param friends addresses to send tokens to.
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the tokens.
     */
    function reserveTokens(
        address[] memory friends,
        uint256 count,
        uint256 selectedNature
    ) external payable onlyOwner {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsReserveBatchSize();

        uint256 totalMinted = _totalMinted(); // track locally to save gas.

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], totalMinted, count, selectedNature);
            totalMinted += count;
        }
    }

    /**
     * @notice Owner: reserve sets for team.
     *
     * @param friends addresses to send tokens to.
     * @param sets the number of sets to mint.
     */
    function reserveSets(address[] memory friends, uint256 sets) external payable onlyOwner {
        if (0 >= sets || sets > MAX_RESERVE_BATCH_SIZE) revert ExceedsReserveBatchSize();

        uint256 totalMinted = _totalMinted(); // track locally to save gas.

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            totalMinted = _internalMintSet(friends[idx], totalMinted, sets);
        }
    }

    /**
     * @notice Presale tokens Phase 1 - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     */
    function presalePhaseOneTokens(
        bytes32[] calldata proof,
        uint256 count,
        uint256 selectedNature
    ) external payable nonReentrant isPhaseOne {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPresaleBatchSize();
        if (msg.value != phaseOnePricePerNft * count) revert InvalidPresalePayment();

        (uint32 presalePhase1Purchases, uint32 otherPhase) = _unpack32(_getAux(msg.sender));

        uint256 newBalance = presalePhase1Purchases + count;

        _setAux(msg.sender, _pack32(uint16(newBalance), otherPhase));

        _proofMintTokensPhaseOne(msg.sender, proof, newBalance, count, selectedNature);
    }

    /**
     * @notice Presale tokens Phase 2 - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     */
    function presalePhaseTwoTokens(
        bytes32[] calldata proof,
        uint256 count,
        uint256 selectedNature
    ) external payable nonReentrant isPhaseTwo {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPresaleBatchSize();
        if (msg.value != phaseTwoPricePerNft * count) revert InvalidPresalePayment();

        (uint32 otherPhase, uint32 presalePhase2Purchases) = _unpack32(_getAux(msg.sender));

        uint256 newBalance = presalePhase2Purchases + count;

        _setAux(msg.sender, _pack32(otherPhase, uint16(newBalance)));

        _proofMintTokensPhaseTwo(msg.sender, proof, newBalance, count, selectedNature);
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     * IMPORTANT: All tokens minted will have the same nature selection.
     *
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     */
    function mintTokens(uint256 count, uint256 selectedNature) external payable nonReentrant isPublicMinting {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPublicMintBatchSize();
        if (msg.value != publicMintPricePerNft * count) revert InvalidPublicMintPayment();

        _internalMintTokens(msg.sender, _totalMinted(), count, selectedNature);
    }

    /**
     * @notice Same as mintTokens(), but with a to: for fiat purchasing.
     *
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     * @param to address where the new token should be sent.
     */
    function mintTokensTo(
        uint256 count,
        uint256 selectedNature,
        address to
    ) external payable nonReentrant isPublicMinting {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPublicMintBatchSize();
        if (msg.value != publicMintPricePerNft * count) revert InvalidPublicMintPayment();
        if (msg.sender != _remoteMinter && _remoteMinter != 0x0000000000000000000000000000000000000000)
            revert InvalidRemoteMinter();

        _internalMintTokens(to, _totalMinted(), count, selectedNature);
    }

    /**
     * @notice Mint function that will mint a single set of tokens, 1 per nature.
     *
     * @param sets the number of sets to mint
     */
    function mintSet(uint256 sets) external payable nonReentrant isPublicMinting {
        if (0 >= sets || sets > 5) revert ExceedsPublicMintBatchSize();
        if (msg.value != publicMintPricePerNft * (4 * sets)) revert InvalidPublicMintPayment();

        _internalMintSet(msg.sender, _totalMinted(), sets);
    }

    /**
     * @notice Bind a Token to a User URI Fragment.
     *
     * This method will convert the token from being a "blank" token with a default
     * piece of artwork to a token with a generative artwork.
     *
     * The initial call to bind a token will have gas refunded according to a committed
     * amount by the project.
     *
     * @param tokenId the token to bind
     * @param userUri the URI fragment for the token
     * @param threefaceSignature an approved signature for the request
     */
    function bindToUser(
        uint256 tokenId,
        string calldata userUri,
        bytes calldata threefaceSignature
    ) external {
        _bindToUser(tokenId, userUri, threefaceSignature);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal pure virtual returns (string memory) {
        // Special: Append the slash, so it looks like '/0'
        return string(abi.encodePacked('/', tokenId.toString()));
    }

    function _internalMintSet(
        address minter,
        uint256 totalMinted,
        uint256 sets
    ) internal returns (uint256) {
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL);

        totalMinted += sets;
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL + 1);

        totalMinted += sets;
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL + 2);

        totalMinted += sets;
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL + 3);

        totalMinted += sets;

        return totalMinted;
    }

    function _internalMintTokens(
        address minter,
        uint256 totalMinted,
        uint256 count,
        uint256 selectedNature
    ) internal {
        if (totalMinted + count > MAX_NFTS_FOR_SALE) revert ExceedsMaxSupply();
        if (selectedNature < NATURE_BASE_VAL + NATURE_MIN || selectedNature > NATURE_BASE_VAL + NATURE_MAX)
            revert InvalidSelectedNature();

        uint24 selectedNatureAs24 = uint24(selectedNature);
        uint256 nextToken = _nextTokenId();

        _safeMint(minter, count);

        _setNature(nextToken, selectedNatureAs24);

        if (count > 1) {
            // Even though this code has to do quite a few duplicate lookups to get the ownerships initialized
            // the gas efficiency is still quite good. It's only about 5% cheaper to modify ERC721a to directly
            // set extra data.
            for (uint256 nextTokenIdx = nextToken + 1; nextTokenIdx < nextToken + count; nextTokenIdx++) {
                _initializeOwnershipAt(nextTokenIdx);
                _setNature(nextTokenIdx, selectedNatureAs24);
            }
        }
    }

    function _proofMintTokensPhaseOne(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 selectedNature
    ) internal {
        uint256 totalMinted = _totalMinted();
        if (totalMinted + count > MAX_NFTS_FOR_PRESALE_1) revert ExceedsPresaleSupply();

        // Verify proof matches expected target total number of claim mints.
        if (!_phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1))) {
            //Zero-based index.
            revert ProofInvalidPresale();
        }

        _internalMintTokens(minter, totalMinted, count, selectedNature);
    }

    function _proofMintTokensPhaseTwo(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 selectedNature
    ) internal {
        // Verify address is eligible for presale mints.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1))) {
            //Zero-based index.
            revert ProofInvalidPresale();
        }

        _internalMintTokens(minter, _totalMinted(), count, selectedNature);
    }

    function _setNatureFragments(uint256[] memory __natureIds, string[] memory __natureUris) internal {
        require(__natureIds.length == __natureUris.length, 'Unmatched arrays');

        for (uint256 idx = 0; idx < __natureIds.length; idx++) {
            _natureUriFragments[__natureIds[idx]] = __natureUris[idx];
        }
    }

    function _bindToUser(
        uint256 tokenId,
        string calldata userUri,
        bytes calldata threefaceSignature
    ) internal canBind {
        require(_exists(tokenId), 'No token');
        require(msg.sender == _ownershipOf(tokenId).addr, 'Not owner');

        TokenBindingData memory currentData = _tokenBindingMap[tokenId];
        uint256 generation = currentData.generation + 1;

        // Verify the new binding.
        _verifyThreefaceBinding(msg.sender, tokenId, generation, userUri, threefaceSignature);

        // Bind the token to a new fragment.
        bool initialBinding = _setBindToUser(tokenId, currentData, userUri);

        if (initialBinding && _isRefundingEnabled()) {
            payable(msg.sender).transfer(bindingRefundAmount);
            emit TokenBindingRefunded(tokenId);
        }
    }

    function _setBindToUser(
        uint256 __tokenId,
        TokenBindingData memory currentData,
        string calldata __userUri
    ) internal returns (bool) {
        bool initialBinding = false;
        if (currentData.isBoundToUser == 0) {
            currentData.tokenId = uint64(__tokenId);
            currentData.isBoundToUser = 1;
            initialBinding = true;
        } else {
            // Emit the previous URI fragment to the event log.
            emit ReleaseURIFragment(__tokenId, currentData.generation, _userUriFragments[__tokenId]);
        }

        currentData.generation++;
        _userUriFragments[__tokenId] = __userUri;

        // Now write it back to the map.
        _tokenBindingMap[__tokenId] = currentData;

        return initialBinding;
    }

    function _setNature(uint256 tokenId, uint24 selectedNature) internal {
        if (selectedNature < NATURE_BASE_VAL + NATURE_MIN || selectedNature > NATURE_BASE_VAL + NATURE_MAX)
            revert InvalidSelectedNature();

        _setExtraDataAt(tokenId, selectedNature);
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal pure override returns (uint24) {
        // Just return the existing extra data, which is the selected Nature for the token. It doesn't matter who minted it, once
        // its set, its set.
        return previousExtraData;
    }

    function _getNature(uint256 tokenId) internal view returns (uint256) {
        uint24 extraData = uint24(_ownershipAt(tokenId).extraData);
        return uint256(extraData);
    }

    function _isBoundToUser(uint256 tokenId) internal view returns (bool) {
        return _tokenBindingMap[tokenId].isBoundToUser == 1;
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _verifyThreefaceBinding(
        address sender,
        uint256 tokenId,
        uint256 generation,
        string calldata userUriFragment,
        bytes calldata threefaceSignature
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(sender, tokenId, generation, userUriFragment));
        return _verify(dataHash, threefaceSignature, _threefaceSigner);
    }

    function _isBindingAllowed() internal view returns (bool) {
        return _bindingControlFlags.getBoolean(BINDING_ALLOWED);
    }

    function _isRefundingEnabled() internal view returns (bool) {
        return _bindingControlFlags.getBoolean(REFUNDING_ENABLED);
    }
}