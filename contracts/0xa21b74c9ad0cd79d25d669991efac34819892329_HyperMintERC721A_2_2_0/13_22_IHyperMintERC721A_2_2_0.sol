// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import 'erc721a/contracts/interfaces/IERC721A.sol';
import './IERC4906.sol';

// ============== Structs ==============
struct GeneralConfig {
    string name;
    string symbol;
    string contractMetadataUrl;
    string tokenMetadataUrl;
    bool allowBuy;
    bool allowPublicTransfer;
    bool enableOpenSeaOperatorFilterRegistry;
    uint256 publicSaleDate;
    uint256 saleCloseDate;
    uint256 primaryRoyaltyFee;
    uint256 secondaryRoyaltyFee;
}

struct TokenConfig {
    uint256 price;
    uint256 maxSupply;
    uint256 maxPerTransaction;
}

struct Addresses {
    address recoveryAddress;
    address collectionOwnerAddress;
    address authorisationAddress;
    address purchaseTokenAddress;
    address managerPrimaryRoyaltyAddress;
    address customerPrimaryRoyaltyAddress;
    address secondaryRoyaltyAddress;
}

interface IHyperMintERC721A_2_2_0 is IERC4906 {
    /* ================= CUSTOM ERRORS ================= */
    error NewSupplyTooLow();
    error MaxSupplyExceeded();
    error SignatureExpired();
    error NotAuthorised();
    error BuyDisabled();
    error InsufficientPaymentValue();
    error PublicSaleClosed();
    error SaleClosed();
    error MaxPerAddressExceeded();
    error MaxPerTransactionExceeded();
    error NonExistentToken();
    error ContractCallBlocked();
    error ImmutableRecoveryAddress();
    error TransfersDisabled();
    error PayoutToManagerFailed();
    error PayoutToCustomerFailed();

    /* ====================== Views ====================== */
    function name() external view returns (string memory collectionName);

    function symbol() external view returns (string memory collectionSymbol);

    function supply() external view returns (uint256 _supply);

    function totalMinted(
        address _addr
    ) external view returns (uint256 numMinted);

    function contractURI() external view returns (string memory uri);

    function tokenURI(
        uint256 _tokenId
    ) external view returns (string memory uri);

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address royaltyAddress, uint256 royaltyAmount);

    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool result);

    /* ================ MUTATIVE FUNCTIONS ================ */

    // ============ Restricted =============
    function setNameAndSymbol(
        string calldata _name,
        string calldata _symbol
    ) external;

    function setMetadataURIs(
        string calldata _contractUri,
        string calldata _tokenUri
    ) external;

    function setDates(uint256 _publicSale, uint256 _saleClosed) external;

    function setTokenConfig(
        uint256 _price,
        uint256 _maxSupply,
        uint256 _maxPerTransaction
    ) external;

    function setAddresses(Addresses calldata _addresses) external;

    function setAllowBuy(bool allowBuy) external;

    function setAllowPublicTransfer(bool _allowPublicTransfer) external;

    function setEnableOpenSeaOperatorFilterRegistry(bool _enable) external;

    function setRoyalty(uint256 primaryFee, uint256 secondaryFee) external;

    // ============== Minting ==============
    function mintBatch(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external;

    // ================ Buy ================
    function buyAuthorised(
        uint256 _amount,
        uint256 _totalPrice,
        uint256 _maxPerAddress,
        uint256 _expires,
        bytes calldata _signature
    ) external payable;

    function buy(uint256 _amount) external payable;

    // ================ Transfers ================
    function transferAuthorised(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _expires,
        bytes calldata _signature
    ) external;
}