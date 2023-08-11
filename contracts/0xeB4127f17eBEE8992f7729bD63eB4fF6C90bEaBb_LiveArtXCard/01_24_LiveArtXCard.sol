// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IV1Memberships.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../libraries/CustomErrors.sol";

contract LiveArtXCard is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC2981Upgradeable
{
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Errors
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    error OwnershipVerificationFailed();
    error InsufficientEtherValue();
    error InsufficientSupply();
    error MaxMintPerAddressReached();
    error MintNotOpened();
    error NotWhitelisted();
    error WithdrawlError();
    error TradingRestricted();
    error IncorrectTokenIdsLength();
    error TooManyRecipients();
    error NoRecipients();

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Events
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /**
     * @dev Emitted when burning a V1 / Reva memberships
     */
    event V1MembershipBurnt(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed level,
        uint256 timestamp
    );

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Constants
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    // IV1Memberships public constant v1MembershipContract =
    //     IV1Memberships(0xbA0137E927d0bAB898F210c679A11e7C684a4E87);
    // IV1Memberships public constant revaMembershipContract =
    //     IV1Memberships(0x95Af4B40E213F824af743EEc4278937985e8baB1);
    IV1Memberships public constant v1MembershipContract =
        IV1Memberships(0xBdCaAB0d1392A391AC91C477fe18a85cBe855aBa);
    IV1Memberships public constant revaMembershipContract =
        IV1Memberships(0x4D13D387E34D412088a6428Cd360a06B533E8A8f);
    uint256 public constant MAX_SUPPLY = 3500;
    uint256 public constant MINT_PRICE = 0.3 ether;
    uint256 public constant PRESALE_MAX_PER_WALLET = 3;
    uint256 public constant AIRDROP_MAX_BATCH_SIZE = 100;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * State
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    mapping(uint256 => uint256) public discountByLevel;
    uint256 public mintStartTimestamp;
    bool public mintOpened;
    uint256 public maxMintPerAddress;
    bytes32 public whitelistMerkleRoot;
    uint256 public preSaleStartTimestamp;
    bool public operatorRegistryDisabled;
    bool public tradingRestricted;
    uint256 public maxSupply;

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("LiveArtXCard", "LAXCard");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __ERC2981_init_unchained();
        discountByLevel[1] = 0.12 ether;
        discountByLevel[2] = 0.17 ether;
        discountByLevel[3] = 0.21 ether;
        discountByLevel[4] = 0.25 ether;
        discountByLevel[5] = 0.3 ether;
        discountByLevel[6] = 0.6 ether;
        maxMintPerAddress = 5;
        _setDefaultRoyalty(address(this), 700);
        maxSupply = MAX_SUPPLY;
        tradingRestricted = true;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Contract management
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setMaxMintPerAddress(
        uint256 _maxMintPerAddress
    ) external onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function setMintStartTimestamp(
        uint256 _mintStartTimestamp
    ) external onlyOwner {
        mintStartTimestamp = _mintStartTimestamp;
    }

    function toggleMintOpened() external onlyOwner {
        mintOpened = !mintOpened;
    }

    function toggletradingRestricted() external onlyOwner {
        tradingRestricted = !tradingRestricted;
    }

    function toggleOperatorRegistry() external onlyOwner {
        operatorRegistryDisabled = !operatorRegistryDisabled;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setDefaultRoyalties(
        address royaltyReceiver,
        uint96 secondaryFeesBPS
    ) external onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, secondaryFeesBPS);
    }

    function setPreSaleStartTimestamp(
        uint256 _preSaleStartTimestamp
    ) external onlyOwner {
        preSaleStartTimestamp = _preSaleStartTimestamp;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Operator registry overides
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        if (tradingRestricted) {
            revert TradingRestricted();
        }
        if (!operatorRegistryDisabled) {
            _checkFilterOperator(operator);
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override {
        if (tradingRestricted) {
            revert TradingRestricted();
        }
        if (!operatorRegistryDisabled) {
            _checkFilterOperator(operator);
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        if (tradingRestricted) {
            revert TradingRestricted();
        }
        if (!operatorRegistryDisabled && from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }

        uint24 lastWhitelistMintBlockNumber = _ownershipAt(tokenId).extraData;
        super.transferFrom(from, to, tokenId);
        _setExtraDataAt(tokenId, lastWhitelistMintBlockNumber);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        if (tradingRestricted) {
            revert TradingRestricted();
        }
        if (!operatorRegistryDisabled && from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        uint24 lastWhitelistMintBlockNumber = _ownershipAt(tokenId).extraData;
        super.safeTransferFrom(from, to, tokenId);
        _setExtraDataAt(tokenId, lastWhitelistMintBlockNumber);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override {
        if (tradingRestricted) {
            revert TradingRestricted();
        }
        if (!operatorRegistryDisabled && from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        uint24 lastWhitelistMintBlockNumber = _ownershipAt(tokenId).extraData;
        super.safeTransferFrom(from, to, tokenId, data);
        _setExtraDataAt(tokenId, lastWhitelistMintBlockNumber);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function isPreSaleOpen() public view returns (bool) {
        return
            preSaleStartTimestamp > 0
                ? block.timestamp >= preSaleStartTimestamp
                : false;
    }

    modifier whenPreSaleActive() {
        if (!isPreSaleOpen()) {
            revert MintNotOpened();
        }
        _;
    }
    modifier whenMintActive() {
        if (
            mintStartTimestamp == 0 ||
            block.timestamp < mintStartTimestamp ||
            !mintOpened
        ) {
            revert MintNotOpened();
        }
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Minting
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function calculateMintingDiscount(
        uint256[] calldata V1TokenIds,
        uint256[] calldata revaTokenIds
    ) internal view returns (uint256 totalDiscount) {
        for (uint256 i = 0; i < V1TokenIds.length; i++) {
            totalDiscount += discountByLevel[
                v1MembershipContract.getMembershipLevelById(V1TokenIds[i])
            ];
        }
        for (uint256 i = 0; i < revaTokenIds.length; i++) {
            totalDiscount += discountByLevel[
                revaMembershipContract.getMembershipLevelById(revaTokenIds[i])
            ];
        }
    }

    function verifyV1Ownership(
        uint256[] calldata tokenIds
    ) internal view returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (v1MembershipContract.ownerOf(tokenIds[i]) != msg.sender) {
                return false;
            }
        }
        return true;
    }

    function verifyRevaOwnership(
        uint256[] calldata tokenIds
    ) internal view returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (revaMembershipContract.ownerOf(tokenIds[i]) != msg.sender) {
                return false;
            }
        }
        return true;
    }

    function _burnRevaTokens(uint256[] calldata tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            revaMembershipContract.burnMembership(tokenIds[i]);
            uint256 level = revaMembershipContract.getMembershipLevelById(
                tokenIds[i]
            );
            emit V1MembershipBurnt(
                msg.sender,
                tokenIds[i],
                level,
                block.timestamp
            );
        }
    }

    function _burnV1Tokens(uint256[] calldata tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            v1MembershipContract.burnMembership(tokenIds[i]);
            uint256 level = v1MembershipContract.getMembershipLevelById(
                tokenIds[i]
            );
            emit V1MembershipBurnt(
                msg.sender,
                tokenIds[i],
                level,
                block.timestamp
            );
        }
    }

    function burnForMint(
        uint256[] calldata v1MembershipIds,
        uint256[] calldata revaMembershipIds,
        uint256 quantity
    ) external payable whenPreSaleActive {
        uint256 totalV1Memberships = v1MembershipIds.length +
            revaMembershipIds.length;

        if (totalV1Memberships == 0) {
            revert OwnershipVerificationFailed();
        }

        if (_totalMinted() + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        bool ownershipVerified = verifyV1Ownership(v1MembershipIds) &&
            verifyRevaOwnership(revaMembershipIds);

        if (!ownershipVerified) {
            revert OwnershipVerificationFailed();
        }

        if (quantity > maxMintPerAddress + totalV1Memberships) {
            revert MaxMintPerAddressReached();
        }

        uint256 batchPrice = MINT_PRICE * quantity;

        uint256 discountAmount = calculateMintingDiscount(
            v1MembershipIds,
            revaMembershipIds
        );

        uint256 discountedBatchPrice;
        if (batchPrice > discountAmount) {
            discountedBatchPrice = batchPrice - discountAmount;
        } else {
            discountedBatchPrice = 0;
        }

        if (discountedBatchPrice > msg.value) {
            revert InsufficientEtherValue();
        }

        _burnV1Tokens(v1MembershipIds);
        _burnRevaTokens(revaMembershipIds);
        _mint(msg.sender, quantity);
    }

    function mintPreSale(
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable whenPreSaleActive {
        // check is WL has already been claimed for this user
        if ((_numberMinted(msg.sender) + quantity) > PRESALE_MAX_PER_WALLET) {
            revert MaxMintPerAddressReached();
        }

        if (_totalMinted() + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf)) {
            revert NotWhitelisted();
        }

        uint256 batchPrice = MINT_PRICE * quantity;

        if (batchPrice > msg.value) {
            revert InsufficientEtherValue();
        }

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable whenMintActive {
        if (_totalMinted() + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        if ((_numberMinted(msg.sender) + quantity) > maxMintPerAddress) {
            revert MaxMintPerAddressReached();
        }

        uint256 batchPrice = MINT_PRICE * quantity;

        if (batchPrice > msg.value) {
            revert InsufficientEtherValue();
        }
        _mint(msg.sender, quantity);
    }

    function adminMint(address recipient, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > maxSupply) {
            revert InsufficientSupply();
        }
        _mint(recipient, quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"description": "The LiveArt X Card -- a new membership created exclusively for collectors and creators -- hopes to bring an end to the biggest problem in the digital art market \u2013 flipping and speculation. The LiveArt X Card will also provide the holders with preferential pricing and exclusive access to historic first NFT mints from world-renowned artists. Moreover, the LiveArt X Card will provide users with a powerful ecosystem built around our $ART token. The $ART ecosystem has been constructed around the utilities connected to buying and holding art and interacting with the art world, embracing creators, collectors, art institutions, and other partners.", "image": "https://pin.ski/3JOTTKN", "animation_url": "https://pin.ski/3FWlZCC", "name": "LiveArt X Card #',
                            Strings.toString(tokenId),
                            '"}'
                        )
                    )
                )
            );
    }

    function numberMinted(address wallet) public view returns (uint256) {
        return _numberMinted(wallet);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Withdrawls
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAmount(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        (bool succeed, ) = recipient.call{value: amount}("");
        if (!succeed) {
            revert WithdrawlError();
        }
    }

    function withdrawAll(address payable recipient) external onlyOwner {
        (bool succeed, ) = recipient.call{value: balance()}("");
        if (!succeed) {
            revert WithdrawlError();
        }
    }

    function airdrop(
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        if (recipients.length == 0) {
            revert NoRecipients();
        }

        if (recipients.length > AIRDROP_MAX_BATCH_SIZE) {
            revert TooManyRecipients();
        }

        if (tokenIds.length != recipients.length) {
            revert IncorrectTokenIdsLength();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransferFrom(owner(), recipients[i], tokenIds[i]);
        }
    }

    /**
     * getLastWhitelistMintBlockNumber function
     * @param tokenId the xCard Token ID
     */
    function getLastWhitelistMintBlockNumber(
        uint256 tokenId
    ) public view returns (uint24) {
        return _ownershipAt(tokenId).extraData;
    }

    /**
     * isValidBlockNumber function
     * @param tokenId the xCard Token ID
     * Note: If tokenId is 0, then user is not an xCard holder
     */
    function setWhitelistBlockNumberAt(uint256 tokenId) external {
        if (tokenId != 0) {
            if (ownerOf(tokenId) == tx.origin) {
                _setExtraDataAt(tokenId, uint24(block.number));
            }
        }
    }

    /**
     * isValidBlockNumber function
     * @param tokenId the xCard Token ID
     * Note: If tokenId is 0, then user is not an xCard holder
     */
    function isValidBlockNumber(uint24 tokenId) external view returns (bool) {
        uint24 lastMintedBlockNumber = getLastWhitelistMintBlockNumber(tokenId);

        // check that the current blocknumber is not within 5 blocks of the last minted block number. 5 block is a safe number to prevent reentrancy and is equal to 1 minute.
        if (lastMintedBlockNumber != 0) {
            if (uint24(block.number) - lastMintedBlockNumber >= 5) {
                return true;
            } else {
                return false;
            }
        }
        return true;
    }

    /**
     * isXCardHolder function
     * @param tokenId the xCard Token ID
     * Note: If tokenId is 0, then user is not an xCard holder
     */
    function isXCardHolder(uint256 tokenId) public view returns (bool) {
        if (tokenId != 0) {
            address xCardOwner = ownerOf(tokenId);
            return xCardOwner != tx.origin;
        }
        return false;
    }
}