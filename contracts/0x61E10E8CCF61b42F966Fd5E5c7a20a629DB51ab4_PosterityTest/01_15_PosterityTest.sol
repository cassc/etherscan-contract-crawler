// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract PosterityTest is ERC2981, ReentrancyGuard, ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_ALLOWLIST_MINT = 1;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_SUPPLY = 256;

    uint256 public pricePerToken = 0.0001 ether;
    uint256 public posterityFee = 0.004 ether;

    address payable public constant POSTERITY_WALLET =
        payable(0xE262AC7c87A23ac9A08d14a5eFfc6BcB7a6b4781);

    bool public isAllowListActive;
    bool public isSaleActive;

    mapping(address => uint256) public allowListNumMinted;
    mapping(uint256 => string) public scripts;
    mapping(uint256 => bytes32) internal _tokenSeeds;

    bytes32 public merkleRoot;
    uint256 public ratioNumerator = 10000;
    uint256 public version = 2;
    string public communityHash;
    string public provenanceHash;
    string public traitScript;
    string public artLicense;
    string public shortDescription;
    string public projectWebsite;
    string public artistName;

    string private _baseURIextended;
    uint256 private _totalPublicSupply;

    // *************************************************************************
    // CUSTOM ERRORS

    /// Allow list sale is not active
    error AllowListIsNotActive();

    /// Not accepting calls from contracts
    error CallerIsAContract();

    /// Purchase would exceed the address's allowlist quota
    error ExceedsMaximumAllowListTokens();

    /// Purchase would exceed the maximum supply
    error ExceedsMaximumSupply();

    /// Purchase would exceed the maximum tokens per purchase
    error ExceedsMaximumTokenPurchase();

    /// Fee withdrawal failed
    error FeeTransferFailed();

    /// Insufficient ETH sent with the call
    error InsufficientEtherValueSent();

    /// Numerator must be between 5000 and 20,000 inclusive
    error InvalidNumerator();

    /// Address is not on the allow list
    error NotOnAllowList();

    /// This function is access restricted
    error OnlyPosterityAccess();

    /// Token sale is not active
    error SaleIsNotActive();

    /// Short description must be 256 bytes or fewer
    error StringTooLong();

    /// This token ID does not exist
    error TokenIDDoesNotExist(uint256 tokenID);

    /// ETH transfer failed
    error TransferFailed();

    // *************************************************************************
    // MODIFIERS

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsAContract();
        _;
    }

    // *************************************************************************
    // FUNCTIONS

    constructor() ERC721("PosterityTest", "PT") {
        _baseURIextended = string.concat(
            "https://api.posterity.io/metadata/",
            Strings.toHexString(address(this)),
            "/"
        );
    }

    /**
     * @notice get the mint cost per token, including token price
     *  and posterity fee
     */
    function pricePerMint() external view returns (uint256) {
        return pricePerToken + posterityFee;
    }

    /**
     * @notice mint tokens on the allow list
     * @param numberOfTokens quantity of tokens to mint
     * @param merkleProof authorisation proof for the allow list
     */
    function mintAllowList(
        uint256 numberOfTokens,
        bytes32[] memory merkleProof
    ) external payable nonReentrant callerIsUser {
        if (!isAllowListActive) revert AllowListIsNotActive();
        if (!onAllowList(msg.sender, merkleProof)) revert NotOnAllowList();

        uint256 minted_ = allowListNumMinted[msg.sender];
        if (numberOfTokens > MAX_ALLOWLIST_MINT - minted_) {
            revert ExceedsMaximumAllowListTokens();
        }

        uint256 currentSupply = _totalPublicSupply;
        _preMintChecksEffectsFees(currentSupply, numberOfTokens);

        allowListNumMinted[msg.sender] = minted_ + numberOfTokens;

        for (uint256 i; i < numberOfTokens; ++i) {
            _mintToken(msg.sender, currentSupply + i);
        }
    }

    /**
     * @notice mint tokens
     * @param numberOfTokens quantity of tokens to mint
     */
    function mint(
        uint256 numberOfTokens
    ) external payable nonReentrant callerIsUser {
        if (!isSaleActive) revert SaleIsNotActive();
        if (numberOfTokens > MAX_PUBLIC_MINT) {
            revert ExceedsMaximumTokenPurchase();
        }

        uint256 currentSupply = _totalPublicSupply;
        _preMintChecksEffectsFees(currentSupply, numberOfTokens);

        for (uint256 i; i < numberOfTokens; ++i) {
            _mintToken(msg.sender, currentSupply + i);
        }
    }

    /**
     * @notice mint reserved tokens to a recipient
     * @param to the token recipient
     * @param numberOfTokens the quantity of tokens to mint
     */
    function devMint(
        address to,
        uint256 numberOfTokens
    ) external onlyOwner nonReentrant {
        uint256 currentSupply = _totalPublicSupply;
        if (currentSupply + numberOfTokens > MAX_SUPPLY)
            revert ExceedsMaximumSupply();

        _totalPublicSupply = currentSupply + numberOfTokens;
        for (uint256 i; i < numberOfTokens; ++i) {
            _mintToken(to, currentSupply + i);
        }
    }

    /**
     * @dev Check token supply and price vs requested number of tokens.
     *  Then update the token supply count and fee total.
     * @param _currentSupply the current token supply, e.g. use totalSupply()
     * @param _numberOfTokens the number of tokens to mint
     */
    function _preMintChecksEffectsFees(
        uint256 _currentSupply,
        uint256 _numberOfTokens
    ) private {
        // checks
        if (_currentSupply + _numberOfTokens > MAX_SUPPLY) {
            revert ExceedsMaximumSupply();
        }

        uint256 feePerToken = posterityFee;
        if ((pricePerToken + feePerToken) * _numberOfTokens > msg.value) {
            revert InsufficientEtherValueSent();
        }

        // effects
        _totalPublicSupply = _currentSupply + _numberOfTokens;

        // trusted call to send posterity fee
        (bool feeSuccess, ) = POSTERITY_WALLET.call{
            value: feePerToken * _numberOfTokens
        }("");
        if (!feeSuccess) revert FeeTransferFailed();
    }

    /**
     * @dev mints a token ID to a specified address and generates
     * a unique, pseudo-random seed for it
     * @param _to token recipient
     * @param _tokenId token ID to mint
     */
    function _mintToken(address _to, uint256 _tokenId) internal {
        bytes32 seed = keccak256(
            abi.encodePacked(
                _tokenId,
                provenanceHash,
                block.prevrandao,
                communityHash
            )
        );
        _tokenSeeds[_tokenId] = seed;
        _safeMint(_to, _tokenId);
    }

    /**
     * @notice start and stop the public sale
     * @param newState true starts, false stops the sale
     */
    function setSaleActive(bool newState) external onlyOwner {
        isSaleActive = newState;
    }

    /**
     * @notice start and stop the allow list sale
     * @param newState true starts, false stops the sale
     */
    function setAllowListActive(bool newState) external onlyOwner {
        isAllowListActive = newState;
    }

    /**
     * @notice set the merkle root for allow list authorization
     * @param _merkleRoot the new merkle root
     */
    function setAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice check if an address is on the allow list
     * @param claimer address to check
     * @param proof merkle proof for the claimer
     */
    function onAllowList(
        address claimer,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @notice check the remaining available allow list mints for an address
     * @param claimer address to check
     * @param proof merkle proof for the claimer
     */
    function numAvailableToMint(
        address claimer,
        bytes32[] memory proof
    ) public view returns (uint256) {
        if (onAllowList(claimer, proof)) {
            return MAX_ALLOWLIST_MINT - allowListNumMinted[claimer];
        } else {
            return 0;
        }
    }

    /**
     * @notice set a script at a specific index
     * @param _index the index in scripts mapping
     * @param _script the script to assign at _index
     */
    function setScript(
        uint256 _index,
        string memory _script
    ) external onlyOwner {
        scripts[_index] = _script;
    }

    /**
     * @notice set the community hash
     * @param _communityHash the new hash
     */
    function setCommunityHash(string memory _communityHash) external onlyOwner {
        communityHash = _communityHash;
    }

    /**
     * @notice set the provenance hash
     * @param _provenanceHash the new hash
     */
    function setProvenanceHash(
        string memory _provenanceHash
    ) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    /**
     * @notice set the traitScript
     * @param _traitScript the new trait script
     */
    function setTraitScript(string memory _traitScript) external onlyOwner {
        traitScript = _traitScript;
    }

    /**
     * @notice get the token seeds associated with a token ID
     * @param _tokenId the token ID to query
     */
    function showTokenSeeds(uint256 _tokenId) external view returns (bytes32) {
        return _tokenSeeds[_tokenId];
    }

    /**
     * @notice get the total number of minted tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalPublicSupply;
    }

    /**
     * @notice check if a token ID has been minted yet
     */
    function isMinted(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice set the base URI for the collection
     * @param baseURI_ the new base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721 _baseURI()}
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @notice get the URI for a token once it has been minted
     * @param _tokenId the token ID to query
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert TokenIDDoesNotExist(_tokenId);
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    /**
     * @notice withdraw all funds from this contract
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @notice set the aspect ratio numerator. Must be between 5000 and 20,000.
     * The denominator is 10,000. Divide numerator by denominator to get the
     * aspect ratio.
     * @param numerator the numerator
     */
    function setRatioNumerator(uint256 numerator) external onlyOwner {
        if (numerator < 5000 || numerator > 20_000) revert InvalidNumerator();
        ratioNumerator = numerator;
    }

    /**
     * @notice set the art license
     * @param _artLicense the license
     */
    function setArtLicense(string memory _artLicense) external onlyOwner {
        artLicense = _artLicense;
    }

    /**
     * @notice set a short description for the collection
     * @param _shortDescription the new description
     */
    function setShortDescription(
        string memory _shortDescription
    ) external onlyOwner {
        if (bytes(_shortDescription).length > 256) revert StringTooLong();
        shortDescription = _shortDescription;
    }

    /**
     * @notice set the project website address
     * @param _projectWebsite the new web address
     */
    function setProjectWebsite(
        string memory _projectWebsite
    ) external onlyOwner {
        projectWebsite = _projectWebsite;
    }

    /**
     * @notice set the artist's name for this collection
     * @param _artistName the artist's name
     */
    function setArtistName(string memory _artistName) external onlyOwner {
        artistName = _artistName;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    // *************************************************************************
    // Posterity Admin

    /**
     * @notice set the fee per mint received by Posterity
     * @param feePerMintInWei the fee per mint, in wei
     */
    function setFee(uint256 feePerMintInWei) external {
        if (msg.sender != POSTERITY_WALLET) revert OnlyPosterityAccess();
        posterityFee = feePerMintInWei;
    }

    // *************************************************************************
    // ERC2981

    /**
     * @notice Get the royalty fee denominator.
     * @dev See {ERC2981-_feeDenominator}.
     */
    function feeDenominator() external pure returns (uint96) {
        return _feeDenominator();
    }

    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}