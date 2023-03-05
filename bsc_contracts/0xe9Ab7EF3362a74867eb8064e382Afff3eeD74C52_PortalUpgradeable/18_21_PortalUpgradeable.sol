//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/INFTSales.sol";
import "./utils/WithdrawableUpgradeable.sol";
import "./utils/ProxyableUpgradeable.sol";

contract PortalUpgradeable is
    Initializable,
    OwnableUpgradeable,
    WithdrawableUpgradeable,
    ProxyableUpgradeable
{
    struct ContractType {
        uint8 shouldBurn;
        uint8 shouldMint;
        uint16 portalNFTType;
        uint256 defaultMintPrice;
        uint256 defaultBurnPrice;
        address burnRecipient;
    }

    struct NFTTypeInfo {
        uint8 hasCustomSettings;
        uint8 nftTypeCanPortalBurnOrTransfer;
        uint8 nftTypeCanPortalMint;
        uint256 nftTypePortalBurnPrice;
        uint256 nftTypePortalMintPrice;
    }

    address public paymentToken;
    address public treasury;
    bool public isPaymentTokenNative;
    uint256 public transactionCount;

    mapping(uint256 => uint8) public processedTransactionId; //portal transactions
    mapping(address => mapping(uint32 => NFTTypeInfo))
        public customNFTTypeInfos; //details for non-default NFT types
    mapping(address => ContractType) public contractTypes; //NFT contracts

    event PortalWizard(
        address indexed user,
        uint256 indexed transactionId,
        address[] contractsToMintFrom,
        uint32[] nftTypesToMint
    );

    error AddressIsZero();
    error CannotBurnType(uint256 nftType);
    error CannotMintType(uint256 nftType);
    error InvalidPaymentAmount(uint256 expectedAmount);
    error InvalidTxOrder();
    error PortalCannotBurn(uint256 nftType);
    error PortalCannotMint(uint256 nftType);
    error TransactionAlreadyProcessed(uint256 transactionId);
    error TreasuryAddressIsZero();

    modifier notZeroAddress(address value) {
        if (value == address(0)) revert AddressIsZero();
        _;
    }

    function initialize(
        address _treasury,
        address _paymentToken,
        bool _isPaymentTokenNative
    )
        public
        initializer
        notZeroAddress(_treasury)
        notZeroAddress(_paymentToken)
    {
        treasury = _treasury;
        paymentToken = _paymentToken;
        isPaymentTokenNative = _isPaymentTokenNative;
        OwnableUpgradeable.__Ownable_init();
    }

    function editContractType(
        address contractAddress,
        bool shouldBurn,
        bool shouldMint,
        address burnRecipient, // can be zero address
        uint16 portalNFTType,
        uint256 defaultBurnPrice,
        uint256 defaultMintPrice
    ) external onlyOwner notZeroAddress(contractAddress) {
        contractTypes[contractAddress] = ContractType({
            shouldBurn: shouldBurn ? 1 : 0,
            shouldMint: shouldMint ? 1 : 0,
            burnRecipient: burnRecipient,
            portalNFTType: portalNFTType,
            defaultBurnPrice: defaultBurnPrice,
            defaultMintPrice: defaultMintPrice
        });
    }

    function getCanBurnOrTransferAndPrice(
        address[] calldata contracts,
        uint32[] calldata nftTypes
    ) external view returns (bool[] memory, uint256[] memory) {
        bool[] memory canBurn = new bool[](nftTypes.length);
        uint256[] memory burnPrice = new uint256[](nftTypes.length);
        for (uint256 x; x < nftTypes.length; x++) {
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[contracts[x]][
                nftTypes[x]
            ];
            bool isCustom = nftTypeInfo.hasCustomSettings == 1;
            ContractType memory cType = contractTypes[contracts[x]];
            canBurn[x] =
                (
                    isCustom
                        ? nftTypeInfo.nftTypeCanPortalBurnOrTransfer
                        : cType.shouldBurn
                ) ==
                1;
            burnPrice[x] = isCustom
                ? nftTypeInfo.nftTypePortalBurnPrice
                : cType.defaultBurnPrice;
        }
        return (canBurn, burnPrice);
    }

    function getCanMintAndPrice(
        address[] calldata contracts,
        uint32[] calldata nftTypes
    ) external view returns (bool[] memory, uint256[] memory) {
        bool[] memory canMint = new bool[](nftTypes.length);
        uint256[] memory mintPrice = new uint256[](nftTypes.length);
        for (uint256 x; x < nftTypes.length; x++) {
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[contracts[x]][
                nftTypes[x]
            ];
            bool isCustom = nftTypeInfo.hasCustomSettings == 1;
            ContractType memory cType = contractTypes[contracts[x]];
            canMint[x] =
                (
                    isCustom
                        ? nftTypeInfo.nftTypeCanPortalMint
                        : cType.shouldMint
                ) ==
                1;
            mintPrice[x] = isCustom
                ? nftTypeInfo.nftTypePortalMintPrice
                : cType.defaultMintPrice;
        }
        return (canMint, mintPrice);
    }

    function getNFTTypeCanPortalMintBurnOrTransfer(
        address[] calldata contracts,
        uint32[] calldata nftTypes
    ) external view returns (bool[] memory, bool[] memory) {
        bool[] memory canMint = new bool[](nftTypes.length);
        bool[] memory canBurn = new bool[](nftTypes.length);
        for (uint256 x; x < nftTypes.length; x++) {
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[contracts[x]][
                nftTypes[x]
            ];
            bool isCustom = nftTypeInfo.hasCustomSettings == 1;
            ContractType memory cType = contractTypes[contracts[x]];
            canBurn[x] =
                (
                    isCustom
                        ? nftTypeInfo.nftTypeCanPortalBurnOrTransfer
                        : cType.shouldBurn
                ) ==
                1;
            canMint[x] =
                (
                    isCustom
                        ? nftTypeInfo.nftTypeCanPortalMint
                        : cType.shouldMint
                ) ==
                1;
        }
        return (canMint, canBurn);
    }

    function getNFTTypePortalPrices(
        address[] calldata contracts,
        uint32[] calldata nftTypes
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory burn = new uint256[](nftTypes.length);
        uint256[] memory mint = new uint256[](nftTypes.length);
        for (uint256 x; x < nftTypes.length; x++) {
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[contracts[x]][
                nftTypes[x]
            ];
            bool isCustom = nftTypeInfo.hasCustomSettings == 1;
            ContractType memory cType = contractTypes[contracts[x]];
            burn[x] = isCustom
                ? nftTypeInfo.nftTypePortalBurnPrice
                : cType.defaultBurnPrice;
            mint[x] = isCustom
                ? nftTypeInfo.nftTypePortalMintPrice
                : cType.defaultMintPrice;
        }
        return (mint, burn);
    }

    function getPriceToBurnOrTransfer(
        address[] calldata contracts,
        uint32[] calldata nftTypes
    ) external view returns (uint256 result) {
        for (uint256 x; x < nftTypes.length; x++) {
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[contracts[x]][
                nftTypes[x]
            ];
            result += nftTypeInfo.hasCustomSettings == 1
                ? nftTypeInfo.nftTypePortalBurnPrice
                : contractTypes[contracts[x]].defaultBurnPrice;
        }
    }

    function getPriceToMint(
        address[] calldata contracts,
        uint32[] calldata nftTypes
    ) public view returns (uint256 result) {
        for (uint256 x; x < nftTypes.length; x++) {
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[contracts[x]][
                nftTypes[x]
            ];
            result += nftTypeInfo.hasCustomSettings == 1
                ? nftTypeInfo.nftTypePortalMintPrice
                : contractTypes[contracts[x]].defaultMintPrice;
        }
    }

    function portalWizard(
        address[] calldata contractsToTransferFrom, //contracts to transfer NFTs from user
        uint256[] calldata tokenIdsToBeTransferred, //NFTs transferred from user
        uint32[] calldata nftTypesToTransferFrom, //NFT types transferred from user
        address[] calldata contractsToMintFrom, //contracts to mint from
        uint32[] calldata nftTypesToMint, //nft types to mint
        uint256 transactionId
    ) external payable {
        if (processedTransactionId[transactionId] == 1)
            revert TransactionAlreadyProcessed(transactionId);
        transactionCount++;
        if (transactionId != transactionCount) revert InvalidTxOrder();
        processedTransactionId[transactionId] = 1;
        uint256 price = _burnOrTransfer(
            contractsToTransferFrom,
            tokenIdsToBeTransferred,
            nftTypesToTransferFrom
        );
        // mint price
        for (uint256 x = 0; x < contractsToMintFrom.length; x++) {
            address _contract = contractsToMintFrom[x];
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[
                contractsToMintFrom[x]
            ][nftTypesToMint[x]];
            price += nftTypeInfo.hasCustomSettings == 1
                ? nftTypeInfo.nftTypePortalMintPrice
                : contractTypes[_contract].defaultMintPrice;
        }

        if (isPaymentTokenNative) {
            if (msg.value != price) revert InvalidPaymentAmount(price);
        } else {
            if (treasury == address(0)) revert TreasuryAddressIsZero();
            IERC20Upgradeable(paymentToken).transferFrom(
                _msgSender(),
                treasury,
                price
            );
        }
        emit PortalWizard(
            _msgSender(),
            transactionId,
            contractsToMintFrom,
            nftTypesToMint
        );
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setNFTTypeInfo(
        address[] calldata contracts,
        uint32[] calldata nftTypes,
        uint256[] calldata burnPrices,
        uint256[] calldata mintPrices,
        bool[] calldata canBurns,
        bool[] calldata canMints
    ) external onlyOwner {
        for (uint256 x; x < nftTypes.length; x++) {
            customNFTTypeInfos[contracts[x]][nftTypes[x]] = NFTTypeInfo({
                hasCustomSettings: 1,
                nftTypePortalBurnPrice: burnPrices[x],
                nftTypePortalMintPrice: mintPrices[x],
                nftTypeCanPortalBurnOrTransfer: canBurns[x] ? 1 : 0,
                nftTypeCanPortalMint: canMints[x] ? 1 : 0
            });
        }
    }

    function setNFTTypeInfoForContract(
        address _contract,
        uint32[] calldata nftTypes,
        uint256[] calldata burnPrices,
        uint256[] calldata mintPrices,
        bool[] calldata canBurns,
        bool[] calldata canMints
    ) external onlyOwner {
        for (uint256 x; x < nftTypes.length; x++) {
            customNFTTypeInfos[_contract][nftTypes[x]] = NFTTypeInfo({
                hasCustomSettings: 1,
                nftTypePortalBurnPrice: burnPrices[x],
                nftTypePortalMintPrice: mintPrices[x],
                nftTypeCanPortalBurnOrTransfer: canBurns[x] ? 1 : 0,
                nftTypeCanPortalMint: canMints[x] ? 1 : 0
            });
        }
    }

    function setPaymentToken(
        address _address,
        bool _isPaymentTokenNative
    ) external onlyOwner {
        paymentToken = _address;
        isPaymentTokenNative = _isPaymentTokenNative;
    }

    function setTreasury(address value) external onlyOwner {
        treasury = value;
    }

    function withdrawNFTs(
        address nftContract,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        for (uint256 x; x < tokenIds.length; ++x) {
            ERC721(nftContract).transferFrom(
                address(this),
                treasury,
                tokenIds[x]
            );
        }
    }

    function _burnOrTransfer(
        address[] calldata contracts,
        uint256[] calldata tokenIds,
        uint32[] calldata nftTypes
    ) private returns (uint256 price) {
        for (uint256 x; x < tokenIds.length; x++) {
            ContractType memory cType = contractTypes[contracts[x]];
            NFTTypeInfo memory nftTypeInfo = customNFTTypeInfos[contracts[x]][
                nftTypes[x]
            ];
            price += nftTypeInfo.hasCustomSettings == 1
                ? nftTypeInfo.nftTypePortalBurnPrice
                : cType.defaultBurnPrice;

            ERC721(contracts[x]).safeTransferFrom(
                _msgSender(),
                cType.burnRecipient != address(0) && cType.shouldBurn == 0
                    ? cType.burnRecipient
                    : address(this),
                tokenIds[x]
            );

            if (cType.shouldBurn == 1) {
                ERC721Burnable(contracts[x]).burn(tokenIds[x]);
            }
        }
    }
}