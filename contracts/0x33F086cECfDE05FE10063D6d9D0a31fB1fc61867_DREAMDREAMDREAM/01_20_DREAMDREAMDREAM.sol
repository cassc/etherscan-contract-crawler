// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
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
 * @notice This contract handles minting DREAMDREAMDREAM tokens.
 */
contract DREAMDREAMDREAM is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981,
    RevokableOperatorFilterer
{
    using ECDSA for bytes32;

    // Default address to subscribe to for determining blocklisted exchanges
    address constant DEFAULT_SUBSCRIPTION =
        address(0x511af84166215d528ABf8bA6437ec4BEcF31934B);
    // Used to validate authorized presale mint addresses
    address private presaleSignerAddress =
        0x999d2e027875e415cF8F15EAE1978e768b071cFC;
    // Address where HeyMint fees are sent
    address public heymintPayoutAddress =
        0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;
    address public royaltyAddress = 0xed76edCDca0f5D6bB19Cb4BCA314D6B4013c8CB6;
    address[] public payoutAddresses = [
        0xed76edCDca0f5D6bB19Cb4BCA314D6B4013c8CB6
    ];
    bool public isPresaleActive;
    bool public isPublicSaleActive;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen;
    // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool public payoutAddressesFrozen;
    string public baseTokenURI =
        "ipfs://bafybeibvhp5cnbysfkslnwg4rrrgqkj2thcyrdh6wah4yu75xyxrcqmnim/";
    // Maximum supply of tokens that can be minted
    uint256 public MAX_SUPPLY = 5600;
    // Total number of tokens available for minting in the presale
    uint256 public PRESALE_MAX_SUPPLY = 5600;
    // Fee paid to HeyMint per NFT minted
    uint256 public heymintFeePerToken;
    uint256 public presaleMintsAllowedPerAddress = 5600;
    uint256 public presaleMintsAllowedPerTransaction = 5600;
    uint256 public presalePrice = 0 ether;
    uint256 public publicMintsAllowedPerAddress = 10;
    uint256 public publicMintsAllowedPerTransaction = 5600;
    uint256 public publicPrice = 0.005 ether;
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint256[] public payoutBasisPoints = [10000];
    uint96 public royaltyFee = 250;

    constructor(uint256 _heymintFeePerToken)
        ERC721A("DREAMDREAMDREAM", "DREAMER")
        RevokableOperatorFilterer(
            0x000000000000AAeB6D7670E522A718067333cd4E,
            DEFAULT_SUBSCRIPTION,
            true
        )
    {
        heymintFeePerToken = _heymintFeePerToken;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        require(
            payoutAddresses.length == payoutBasisPoints.length,
            "PAYOUT_ARRAYS_NOT_SAME_LENGTH"
        );
        uint256 totalPayoutBasisPoints = 0;
        for (uint256 i = 0; i < payoutBasisPoints.length; i++) {
            totalPayoutBasisPoints += payoutBasisPoints[i];
        }
        require(
            totalPayoutBasisPoints == 10000,
            "TOTAL_BASIS_POINTS_MUST_BE_10000"
        );
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
     * @notice To be updated by contract owner to allow public sale minting
     */
    function setPublicSaleState(bool _saleActiveState) external onlyOwner {
        require(
            isPublicSaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPublicSaleActive = _saleActiveState;
    }

    /**
     * @notice Update the public mint price
     */
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the public sale
     */
    function setPublicMintsAllowedPerAddress(uint256 _mintsAllowed)
        external
        onlyOwner
    {
        publicMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum public mints allowed per a given transaction
     */
    function setPublicMintsAllowedPerTransaction(uint256 _mintsAllowed)
        external
        onlyOwner
    {
        publicMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Allow for public minting of tokens
     */
    function mint(uint256 numTokens)
        external
        payable
        nonReentrant
        originalUser
    {
        require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");

        require(
            numTokens <= publicMintsAllowedPerTransaction,
            "MAX_MINTS_PER_TX_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <=
                publicMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        require(totalSupply() + numTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        uint256 heymintFee = numTokens * heymintFeePerToken;
        require(
            msg.value == publicPrice * numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );

        (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
        require(success, "Transfer failed.");
        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= MAX_SUPPLY) {
            isPublicSaleActive = false;
        }
    }

    /**
     * @notice To be updated by contract owner to allow presale minting
     */
    function setPresaleState(bool _saleActiveState) external onlyOwner {
        require(
            isPresaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPresaleActive = _saleActiveState;
    }

    /**
     * @notice Update the presale mint price
     */
    function setPresalePrice(uint256 _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the presale
     */
    function setPresaleMintsAllowedPerAddress(uint256 _mintsAllowed)
        external
        onlyOwner
    {
        presaleMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given transaction
     */
    function setPresaleMintsAllowedPerTransaction(uint256 _mintsAllowed)
        external
        onlyOwner
    {
        presaleMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Reduce the max supply of tokens available to mint in the presale
     * @param _newPresaleMaxSupply The new maximum supply of presale tokens available to mint
     */
    function reducePresaleMaxSupply(uint256 _newPresaleMaxSupply)
        external
        onlyOwner
    {
        require(
            _newPresaleMaxSupply < PRESALE_MAX_SUPPLY,
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        PRESALE_MAX_SUPPLY = _newPresaleMaxSupply;
    }

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(address _presaleSignerAddress)
        external
        onlyOwner
    {
        require(_presaleSignerAddress != address(0));
        presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     */
    function verifySignerAddress(bytes32 messageHash, bytes calldata signature)
        private
        view
        returns (bool)
    {
        return
            presaleSignerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 numTokens,
        uint256 maximumAllowedMints
    ) external payable nonReentrant originalUser {
        require(isPresaleActive, "PRESALE_IS_NOT_ACTIVE");

        require(
            numTokens <= presaleMintsAllowedPerTransaction,
            "MAX_MINTS_PER_TX_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <=
                presaleMintsAllowedPerAddress,
            "MAX_MINTS_PER_ADDRESS_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <= maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            totalSupply() + numTokens <= PRESALE_MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 heymintFee = numTokens * heymintFeePerToken;
        require(
            msg.value == presalePrice * numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            keccak256(abi.encode(msg.sender, maximumAllowedMints)) ==
                messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );

        (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
        require(success, "Transfer failed.");
        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= PRESALE_MAX_SUPPLY) {
            isPresaleActive = false;
        }
    }

    /**
     * @notice Freeze all payout addresses and percentages so they can never be changed again
     */
    function freezePayoutAddresses() external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_ALREADY_FROZEN");
        payoutAddressesFrozen = true;
    }

    /**
     * @notice Update payout addresses and basis points for each addresses' respective share of contract funds
     */
    function updatePayoutAddressesAndBasisPoints(
        address[] calldata _payoutAddresses,
        uint256[] calldata _payoutBasisPoints
    ) external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
        require(
            _payoutAddresses.length == _payoutBasisPoints.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _payoutBasisPoints.length; i++) {
            totalBasisPoints += _payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "TOTAL_BASIS_POINTS_MUST_BE_10000");
        payoutAddresses = _payoutAddresses;
        payoutBasisPoints = _payoutBasisPoints;
    }

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() external nonReentrant onlyOwner {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 amount = (balance * payoutBasisPoints[i]) / 10000;
            (bool success, ) = payoutAddresses[i].call{value: amount}("");
            require(success, "Transfer failed.");
        }
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