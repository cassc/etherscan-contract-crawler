// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/IERC4907A.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";


contract degentstester is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981
{
    // Address where burnt tokens are sent
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    // Address of the smart contract used to check if an operator address is from a blocklisted exchange
    address public blocklistContractAddress;
    address public burnToMintContractAddress =
        0x3b0Daea2634F111DBA1344768D34e15Ffea8b81f;
    address public royaltyAddress = 0xF5d96c4675ee80E72005A24B7581aF8Aa5b063BA;
    address[] public payoutAddresses = [
        0xF5d96c4675ee80E72005A24B7581aF8Aa5b063BA
    ];
    // Permanently disable the blocklist so all exchanges are allowed
    bool public blocklistPermanentlyDisabled;
    // If true tokens can be burned in order to mint
    bool public burnClaimActive;
    bool public isPublicSaleActive;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen;
    // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool public payoutAddressesFrozen;
    // If true, the exchange represented by a uint256 integer is blocklisted and cannot be used to transfer tokens
    mapping(uint256 => bool) public isExchangeBlocklisted;
    string public baseTokenURI =
        "";
    // Maximum supply of tokens that can be minted
    uint256 public MAX_SUPPLY = 25;
    uint256 public PUBLIC_CURRENT_SUPPLY = 10;
    uint256 public PUBLIC_COUNTER;
    // uint256 public BURN_CURRENT_SUPPLY = 10;
    uint256 public mintsPerBurn = 1;
    uint256 public newBurnID;
    uint256 public publicMintsAllowedPerTransaction = 1;
    uint256 public publicPrice = 0.0001 ether;
    uint256[] public payoutBasisPoints = [10000];
    uint96 public royaltyFee = 5;

    constructor(address _blocklistContractAddress) ERC721A("degentstester", "dtester") {
        blocklistContractAddress = _blocklistContractAddress;
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
        isExchangeBlocklisted[2] = true;
        isExchangeBlocklisted[3] = true;
        isExchangeBlocklisted[4] = true;
        isExchangeBlocklisted[5] = true;
        isExchangeBlocklisted[6] = true;
        isExchangeBlocklisted[7] = true;
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

    
    function changePublicSupply(uint256 _newPublicSupply) external onlyOwner {
        require(_newPublicSupply < MAX_SUPPLY, "NEW_PUBLIC_SUPPLY_TOO_HIGH");
        require(
            _newPublicSupply >= totalSupply(),
            "SUPPLY_LOWER_THAN_MINTED_TOKENS"
        );
        PUBLIC_CURRENT_SUPPLY = _newPublicSupply;
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

    function publicCounter() public view returns (uint256) {
        return PUBLIC_COUNTER;
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
        require(totalSupply() + numTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        require(PUBLIC_COUNTER + numTokens <= PUBLIC_CURRENT_SUPPLY, "PUBLIC_SUPPLY_EXCEEDED");
        require(msg.value == publicPrice * numTokens, "PAYMENT_INCORRECT");

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= MAX_SUPPLY) {
            isPublicSaleActive = false;
        }
        for (uint256 i = 0; i < numTokens; i++) {
            PUBLIC_COUNTER++;
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

    function burnmrCollectoor(uint256 amount)
        external
        nonReentrant
        originalUser
    {
        require(burnClaimActive, "BURN_CLAIM_IS_NOT_ACTIVE");
        require(
            totalSupply() + (amount * mintsPerBurn) <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        IERC1155Basic ExternalERC1155BurnContract = IERC1155Basic(
            burnToMintContractAddress
        );
        require(
            ExternalERC1155BurnContract.balanceOf(msg.sender, 3) >= amount, /**tokenID of burn**/
            "NOT_ENOUGH_TOKENS_OWNED"
        );
        ExternalERC1155BurnContract.safeTransferFrom( /**tokenID of burn**/
            msg.sender,
            burnAddress,
            3,
            amount,
            ""
        );
        _safeMint(msg.sender, amount * mintsPerBurn);
    }

    function burnmrSpectaculoor(uint256 amount)
        external
        nonReentrant
        originalUser
    {
        require(burnClaimActive, "BURN_CLAIM_IS_NOT_ACTIVE");
        require(
            totalSupply() + (amount * mintsPerBurn) <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        IERC1155Basic ExternalERC1155BurnContract = IERC1155Basic(
            burnToMintContractAddress
        );
        require(
            ExternalERC1155BurnContract.balanceOf(msg.sender, 4) >= amount, /**tokenID of burn**/
            "NOT_ENOUGH_TOKENS_OWNED"
        );
        ExternalERC1155BurnContract.safeTransferFrom( /**tokenID of burn**/
            msg.sender,
            burnAddress,
            4,
            amount,
            ""
        );
        _safeMint(msg.sender, amount * mintsPerBurn);
    }

    function burnmrEarly(uint256 amount)
        external
        nonReentrant
        originalUser
    {
        require(burnClaimActive, "BURN_CLAIM_IS_NOT_ACTIVE");
        require(
            totalSupply() + (amount * mintsPerBurn) <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        IERC1155Basic ExternalERC1155BurnContract = IERC1155Basic(
            burnToMintContractAddress
        );
        require(
            ExternalERC1155BurnContract.balanceOf(msg.sender, 11) >= amount, /**tokenID of burn**/
            "NOT_ENOUGH_TOKENS_OWNED"
        );
        ExternalERC1155BurnContract.safeTransferFrom( /**tokenID of burn**/
            msg.sender,
            burnAddress,
            11,
            amount,
            ""
        );
        _safeMint(msg.sender, amount * mintsPerBurn);
    }

    /**
     * update a new burn tokenID to be burned
     */
    function updatenewBurnID(uint256 _newBurnID) external onlyOwner {
        newBurnID = _newBurnID;
    }

    function burnupdatednewBurnXX(uint256 amount)
        external
        nonReentrant
        originalUser
    {
        require(burnClaimActive, "BURN_CLAIM_IS_NOT_ACTIVE");
        require(
            totalSupply() + (amount * mintsPerBurn) <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        IERC1155Basic ExternalERC1155BurnContract = IERC1155Basic(
            burnToMintContractAddress
        );
        require(
            ExternalERC1155BurnContract.balanceOf(msg.sender, newBurnID) >= amount, /**tokenID of burn**/
            "NOT_ENOUGH_TOKENS_OWNED"
        );
        ExternalERC1155BurnContract.safeTransferFrom( /**tokenID of burn**/
            msg.sender,
            burnAddress,
            newBurnID,
            amount,
            ""
        );
        _safeMint(msg.sender, amount * mintsPerBurn);
    }

    /**
     * @dev Require that the address being approved is not from a blocklisted exchange
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        uint256 operatorExchangeId = IExchangeOperatorAddressList(
            blocklistContractAddress
        ).operatorAddressToExchange(operator);
        require(
            blocklistPermanentlyDisabled ||
                !isExchangeBlocklisted[operatorExchangeId],
            "BLOCKLISTED_EXCHANGE"
        );
        _;
    }

    /**
     * @notice Update blocklist contract address to a custom contract address if desired for custom functionality
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
            "ARRAYS_MUST_BE_SAME_LENGTH"
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

interface IERC1155Basic {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IExchangeOperatorAddressList {
    function operatorAddressToExchange(address operatorAddress)
        external
        view
        returns (uint256);
}