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

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting Dream no Dream tokens.
 */
contract DreamNoDream is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981
{
    using ECDSA for bytes32;

    // Used to validate authorized presale mint addresses
    address private presaleSignerAddress =
        0xD42ea665B113aD65F01910975FcF834155Fc80C0;
    // Address of the smart contract used to check if an operator address is from a blocklisted exchange
    address public blocklistContractAddress;
    address public freeClaimContractAddress =
        0xB9970A24035e54353893945E03871395De12865a;
    address public royaltyAddress = 0x0d0E03315d5E86a23eb643770008B331e77ef7c8;
    address[] public payoutAddresses = [
        0x0d0E03315d5E86a23eb643770008B331e77ef7c8
    ];
    // Permanently disable the blocklist so all exchanges are allowed
    bool public blocklistPermanentlyDisabled = false;
    bool public freeClaimActive = false;
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen = false;
    // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool public payoutAddressesFrozen = false;
    // If true token has already been used to claim and cannot be used again
    mapping(uint256 => bool) public freeClaimUsed;
    // If true, the exchange represented by a uint256 integer is blocklisted and cannot be used to transfer tokens
    mapping(uint256 => bool) public isExchangeBlocklisted;
    string public baseTokenURI =
        "ipfs://bafybeic6lej6fua7h6cplg5szguiyt54bijrqy27fqydcqwnzjdgnlgffm/";
    // Maximum supply of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 946;
    // Total number of tokens available for minting in the presale
    uint256 public constant PRESALE_MAX_SUPPLY = 946;
    uint256 public mintsPerClaim = 1;
    uint256 public presaleMintsAllowedPerAddress = 2;
    uint256 public presaleMintsAllowedPerTransaction = 2;
    uint256 public presalePrice = 0.004 ether;
    uint256 public publicMintsAllowedPerAddress = 4;
    uint256 public publicMintsAllowedPerTransaction = 4;
    uint256 public publicPrice = 0.008 ether;
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint256[] public payoutBasisPoints = [10000];
    uint96 public royaltyFee = 500;

    constructor(address _blocklistContractAddress)
        ERC721A("Dream no Dream", "DND")
    {
        blocklistContractAddress = _blocklistContractAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        require(
            payoutAddresses.length == payoutBasisPoints.length,
            "PAYOUT_ADDRESSES_AND_PAYOUT_BASIS_POINTS_MUST_BE_SAME_LENGTH"
        );
        uint256 totalPayoutBasisPoints = 0;
        for (uint256 i = 0; i < payoutBasisPoints.length; i++) {
            totalPayoutBasisPoints += payoutBasisPoints[i];
        }
        require(
            totalPayoutBasisPoints == 10000,
            "TOTAL_PAYOUT_BASIS_POINTS_MUST_BE_10000"
        );
        isExchangeBlocklisted[6] = true;
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "Cannot call from contract address");
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
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        baseTokenURI = _newBaseURI;
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
            "RECEIVERS_AND_MINT_NUMBERS_MUST_BE_SAME_LENGTH"
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
        require(msg.value == publicPrice * numTokens, "PAYMENT_INCORRECT");

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
        require(msg.value == presalePrice * numTokens, "PAYMENT_INCORRECT");
        require(
            keccak256(abi.encode(msg.sender, maximumAllowedMints)) ==
                messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= PRESALE_MAX_SUPPLY) {
            isPresaleActive = false;
        }
    }

    /**
     * @notice Freeze all metadata so it can never be changed again
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
            require(
                payable(payoutAddresses[i]).send(
                    (balance * payoutBasisPoints[i]) / 10000
                )
            );
        }
    }

    /**
     * @notice To be updated by contract owner to allow free claiming tokens
     */
    function setFreeClaimState(bool _freeClaimActive) external onlyOwner {
        require(
            freeClaimActive != _freeClaimActive,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        freeClaimActive = _freeClaimActive;
    }

    /**
     * @notice Update the number of free mints claimable per token redeemed from the external ERC721 contract
     */
    function updateMintsPerClaim(uint256 _mintsPerClaim) external onlyOwner {
        mintsPerClaim = _mintsPerClaim;
    }

    /**
     * @notice Free claim token when msg.sender owns the token in the external contract
     */
    function freeClaim(uint256[] calldata _tokenIDs)
        external
        nonReentrant
        originalUser
    {
        require(freeClaimActive, "FREE_CLAIM_IS_NOT_ACTIVE");
        require(
            totalSupply() + (_tokenIDs.length * mintsPerClaim) <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        ERC721A ExternalERC721FreeClaimContract = ERC721A(
            freeClaimContractAddress
        );
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                ExternalERC721FreeClaimContract.ownerOf(_tokenIDs[i]) ==
                    msg.sender,
                "DOES_NOT_OWN_TOKEN_ID"
            );
            require(!freeClaimUsed[_tokenIDs[i]], "TOKEN_ALREADY_CLAIMED");
            freeClaimUsed[_tokenIDs[i]] = true;
        }
        _safeMint(msg.sender, _tokenIDs.length * mintsPerClaim);
    }

    /**
     * @notice Update blocklist contract address to a custom contract addresss if desired for custom functionality
     */
    function updateBlocklistContractAddress(address _blocklistContractAddress)
        external
        onlyOwner
    {
        blocklistContractAddress = _blocklistContractAddress;
    }

    /**
     * @notice Permanently disable the blocklist so all exchanges are allowed forever
     */
    function permanentlyDisableBlocklist() external onlyOwner {
        require(!blocklistPermanentlyDisabled, "BLOCKLIST_ALREADY_DISABLED");
        blocklistPermanentlyDisabled = true;
    }

    /**
     * @notice Set or unset an exchange contract address as blocklisted
     */
    function updateBlocklistedExchanges(
        uint256[] calldata exchanges,
        bool[] calldata blocklisted
    ) external onlyOwner {
        require(
            exchanges.length == blocklisted.length,
            "EXCHANGES_AND_BLOCKLISTED_MUST_BE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < exchanges.length; i++) {
            isExchangeBlocklisted[exchanges[i]] = blocklisted[i];
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        uint256 operatorExchangeId = IExchangeOperatorAddressList(
            blocklistContractAddress
        ).operatorAddressToExchange(msg.sender);
        require(
            blocklistPermanentlyDisabled ||
                !isExchangeBlocklisted[operatorExchangeId],
            "BLOCKLISTED_EXCHANGE"
        );
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }
}

interface IExchangeOperatorAddressList {
    function operatorAddressToExchange(address operatorAddress)
        external
        view
        returns (uint256);
}