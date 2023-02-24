// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableOperatorFilterer.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting ABSTRASCII AAA SKULLS tokens.
 */
contract ABSTRASCIIAAASKULLS is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981,
    RevokableOperatorFilterer
{
    // Address where burnt tokens are sent
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    // Default address to subscribe to for determining blocklisted exchanges
    address constant DEFAULT_SUBSCRIPTION =
        address(0x511af84166215d528ABf8bA6437ec4BEcF31934B);
    address public burnToMintContractAddress =
        0x8A04921c61F0f9850A02957530BdbA4aB50312D2;
    // Address where HeyMint fees are sent
    address public heymintPayoutAddress =
        0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;
    address public royaltyAddress = 0x8008E57bA1A9FdB38093556f332cdE2AB41A3678;
    // If true tokens can be burned in order to mint
    bool public burnClaimActive;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen;
    string public baseTokenURI =
        "ipfs://bafybeia7vnnu2ffiw4zvqllq54ky5vbnyrjwjgijiikekjqg7h2ta3jyte/";
    // Maximum supply of tokens that can be minted
    uint256 public MAX_SUPPLY = 2448;
    // Fee paid to HeyMint per NFT minted
    uint256 public heymintFeePerToken;
    uint256 public mintsPerBurn = 1;
    uint96 public royaltyFee = 500;

    constructor(uint256 _heymintFeePerToken)
        ERC721A("ABSTRASCII AAA SKULLS", "AAASKULL")
        RevokableOperatorFilterer(
            0x000000000000AAeB6D7670E522A718067333cd4E,
            DEFAULT_SUBSCRIPTION,
            true
        )
    {
        heymintFeePerToken = _heymintFeePerToken;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "CANNOT_CALL_FROM_CONTRACT");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Wraps and exposes publicly _numberMinted() from ERC721A
     */
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Reduce the max supply of tokens
     * @param _newMaxSupply The new maximum supply of tokens available to mint
     */
    function reduceMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(_newMaxSupply < MAX_SUPPLY, "NEW_MAX_SUPPLY_TOO_HIGH");
        require(
            _newMaxSupply >= totalSupply(),
            "SUPPLY_LOWER_THAN_MINTED_TOKENS"
        );
        MAX_SUPPLY = _newMaxSupply;
    }

    /**
     * @notice Freeze metadata so it can never be changed again
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        metadataFrozen = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, ERC4907A)
        returns (bool)
    {
        // Supports the following interfaceIds:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4907: 0xad092b5c
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC4907A.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow owner to send 'mintNumber' tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256[] calldata mintNumber)
        external
        onlyOwner
    {
        require(
            receivers.length == mintNumber.length,
            "ARRAYS_MUST_BE_SAME_LENGTH"
        );
        uint256 totalMint = 0;
        for (uint256 i = 0; i < mintNumber.length; i++) {
            totalMint += mintNumber[i];
        }
        require(totalSupply() + totalMint <= MAX_SUPPLY, "MINT_TOO_LARGE");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber[i]);
        }
    }

    /**
     * @notice To be updated by contract owner to allow burning to claim a token
     */
    function setBurnClaimState(bool _burnClaimActive) external onlyOwner {
        require(
            burnClaimActive != _burnClaimActive,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        burnClaimActive = _burnClaimActive;
    }

    /**
     * @notice Update the number of free mints claimable per token burned
     */
    function updateMintsPerBurn(uint256 _mintsPerBurn) external onlyOwner {
        mintsPerBurn = _mintsPerBurn;
    }

    function burnERC721ToMint(uint256[] calldata _tokenIds)
        external
        nonReentrant
        originalUser
    {
        require(burnClaimActive, "BURN_CLAIM_IS_NOT_ACTIVE");
        uint256 numberOfTokens = _tokenIds.length;
        require(numberOfTokens > 0, "NO_TOKEN_IDS_PROVIDED");
        require(
            totalSupply() + (numberOfTokens * mintsPerBurn) <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        ERC721A ExternalERC721BurnContract = ERC721A(burnToMintContractAddress);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(
                ExternalERC721BurnContract.ownerOf(_tokenIds[i]) == msg.sender,
                "DOES_NOT_OWN_TOKEN_ID"
            );
            ExternalERC721BurnContract.transferFrom(
                msg.sender,
                burnAddress,
                _tokenIds[i]
            );
        }
        _safeMint(msg.sender, numberOfTokens * mintsPerBurn);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(to)
    {
        super.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}