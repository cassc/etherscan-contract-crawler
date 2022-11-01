// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IMinerPublicBuildingInterface.sol";
import "./interfaces/ISignatureValidator.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IParcelInterface.sol";
import "./interfaces/INetGymStreet.sol";
import "./interfaces/IERC721Base.sol";
import "./interfaces/IBuyAndBurn.sol";
import "./interfaces/IMinerNFT.sol";
import "./interfaces/IMining.sol";
import "./interfaces/IAmountsDistributor.sol";

contract Municipality is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct AttachedMiner {
        uint256 parcelId;
        uint256 minerId;
    }

    struct Parcel {
        uint16 x;
        uint16 y;
        uint8 parcelType;
        uint8 parcelLandType;
    }

    // Used to keep Parcel information
    struct ParcelInfo {
        bool isUpgraded;
        uint8 parcelType;
        uint8 parcelLandType;
        bool isValid;
    }

    // bundlePrice is not used anymore
    struct BundleInfo {
        uint256 parcelsAmount;
        uint256 minersAmount;
        uint256 bundlePrice;
        uint256 discountPct;
    }

    struct SuperBundleInfo {
        uint256 parcelsAmount;
        uint256 minersAmount;
        uint256 upgradesAmount;
        uint256 vouchersAmount;
        uint256 discountPct;
    }

    struct ParcelsMintSignature {
        Parcel[] parcels;
        bytes[] signatures;
    }

    struct MintedNFT {
        uint256 firstNFTId;
        uint256 count;
    }

    struct UserMintableNFTAmounts {
        uint256 parcels;
        uint256 miners;
        uint256 upgrades;
    }

    uint8 private constant OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS = 10;
    uint8 private constant OPERATION_TYPE_MINT_MINERS = 20;
    uint8 private constant OPERATION_TYPE_PURCHASE_ELECTRICITY = 30;
    uint8 private constant OPERATION_TYPE_PURCHASE_REPAIR = 40;

    uint8 private constant MINER_STATUS_DETACHED = 10;
    uint8 private constant MINER_STATUS_ATTACHED = 20;

    uint8 private constant PARCEL_TYPE_STANDARD = 10;
    uint8 private constant PARCEL_TYPE_BUSINESS = 20;

    uint8 private constant PARCEL_LAND_TYPE_NEXT_TO_OCEAN = 10;
    uint8 private constant PARCEL_LAND_TYPE_NEAR_OCEAN = 20;
    uint8 private constant PARCEL_LAND_TYPE_INLAND = 30;

    uint8 private constant BUNDLE_TYPE_PARCELS_MINERS_1 = 0;
    uint8 private constant BUNDLE_TYPE_PARCELS_1 = 1;
    uint8 private constant BUNDLE_TYPE_PARCELS_2 = 2;
    uint8 private constant BUNDLE_TYPE_PARCELS_3 = 3;
    uint8 private constant BUNDLE_TYPE_PARCELS_4 = 4;
    uint8 private constant BUNDLE_TYPE_PARCELS_5 = 5;
    uint8 private constant BUNDLE_TYPE_PARCELS_6 = 6;
    uint8 private constant BUNDLE_TYPE_MINERS_1 = 7;
    uint8 private constant BUNDLE_TYPE_MINERS_2 = 8;
    uint8 private constant BUNDLE_TYPE_MINERS_3 = 9;
    uint8 private constant BUNDLE_TYPE_MINERS_4 = 10;
    uint8 private constant BUNDLE_TYPE_MINERS_5 = 11;
    uint8 private constant BUNDLE_TYPE_MINERS_6 = 12;
    uint8 private constant BUNDLE_TYPE_SUPER_1 = 13;
    uint8 private constant BUNDLE_TYPE_SUPER_2 = 14;
    uint8 private constant BUNDLE_TYPE_SUPER_3 = 15;
    uint8 private constant BUNDLE_TYPE_SUPER_4 = 16;

    
    /// @notice Pricing information (in BUSD)
    uint256 public upgradePrice;
    uint256 public minerPrice;
    uint256 public minerRepairPrice;
    uint256 public electricityVoucherPrice;

    /// @notice Addresses of Gymstreet smart contracts
    address public standardParcelNFTAddress;
    address public businessParcelNFTAddress;
    address public minerV1NFTAddress;
    address public miningAddress;
    address public busdAddress;
    address public netGymStreetAddress;
    address public signatureValidatorAddress;

    mapping(address => uint256) public userToPurchasedAmountMapping;

    /// @notice Parcels pricing changes per percentage
    mapping(uint256 => uint256) public soldCountToStandardParcelPriceMapping;
    mapping(uint256 => uint256) public soldCountToBusinessParcelPriceMapping;
    uint256 public currentlySoldStandardParcelsCount;
    uint256 public currentlySoldBusinessParcelsCount;
    uint256 public currentStandardParcelPrice;
    uint256 public currentBusinessParcelPrice;

    /// @notice Parcel <=> Miner attachments and Parcel/Miner properties
    mapping(uint256 => uint256[]) public parcelMinersMapping;
    mapping(uint256 => uint256) public minerParcelMapping;
    uint8 public standardParcelSlotsCount;
    uint8 public upgradedParcelSlotsCount;

    /// @notice Electricity voucher mapping to user who owns them
    mapping(address => uint256) public userToElectricityVoucherAmountMapping;

    /// @notice Timestamps the user requested repair
    mapping(address => uint256[]) public userToRepairDatesMapping;

    /// @notice Signatures when minting a parcel
    mapping(bytes => bool) public mintParcelsUsedSignaturesMapping;

    /// @notice Array of all available bundles OLD VERSION DEPRICATED
    BundleInfo[6] public bundles;

    /// @notice Indicator if the sales can happen
    bool public isSaleActive;

    address public minerPublicBuildingAddress;
    address public amountsDistributorAddress;

    /// @notice Array of all available bundles
    BundleInfo[13] public newBundles;

    
    struct LastPurchaseData {
        uint256 lastPurchaseDate;
        uint256 expirationDate;
        uint256 dollarValue;
    }
    mapping(address => LastPurchaseData) public lastPurchaseData;
    bool public basicBundleActivated;
    SuperBundleInfo[4] public superBundlesInfos;
    mapping(address => UserMintableNFTAmounts) public usersMintableNFTAmounts;

    // ------------------------------------ EVENTS ------------------------------------ //

    event ParcelsSoldCountPricingSet(
        uint256[] indexed standardParcelPrices, 
        uint256[] indexed businessParcelPrices
    );
    event BundlesSet(BundleInfo[13] indexed bundles);
    event SuperBundlesSet(SuperBundleInfo[4] indexed bundles);
    event ParcelsSlotsCountSet(
        uint8 indexed standardParcelSlotsCount,
        uint8 indexed upgradedParcelSlotsCount
    );
    event PurchasePricesSet(
        uint256 upgradePrice,
        uint256 minerPrice,
        uint256 minerRepairPrice,
        uint256 electricityVoucherPrice
    );
    event SaleActivationSet(bool indexed saleActivation);
    event BundlePurchased(address indexed user, uint256 indexed bundleType);
    event SuperBundlePurchased(address indexed user, uint256 indexed bundleType);
    event MinerAttached(address user, uint256 indexed parcelId, uint256 indexed minerId);
    event MinerDetached(address indexed user, uint256 indexed parcelId, uint256 indexed minerId);
    event VouchersPurchased(address indexed user, uint256 vouchersCount);
    event MinersRepaired(address indexed user, uint256 minersCount);
    event VouchersApplied(address indexed user, uint256[] minerIds);
    event NFTContractAddressesSet(address[9] indexed _nftContractAddresses);
    event BasicBundleActivationSet(bool indexed _activation);

    /// @notice Modifier for 0 address check
    modifier notZeroAddress() {
        require(address(0) != msg.sender, "Municipality: Caller can not be address 0");
        _;
    }

    /// @notice Modifier not to allow sales when it is made inactive
    modifier onlySaleActive() {
        require(isSaleActive, "Municipality: Sale is deactivated now");
        _;
    }

    /// @notice Access to only the miner public building
    modifier onlyMinerPublicBuilding() {
        require(msg.sender == minerPublicBuildingAddress, "Municipality: This function is available only to a miner public building");
        _;
    }

    // @notice Proxy SC support - initialize internal state
    function initialize(
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    receive() external payable {}

    fallback() external payable {}

    /// @notice Public interface

    /// @notice Array of the prices is given in the following way [sold_count1, price1, sold_count2, price2, ...]
    function setParcelsSoldCountPricing(
        uint256[] calldata _standardParcelPrices,
        uint256[] calldata _businessParcelPrices
    ) external onlyOwner notZeroAddress {
        require(_standardParcelPrices[0] == 0, "Municipality: The given standard parcel array must start from 0");
        require(_businessParcelPrices[0] == 0, "Municipality: The given business parcel array must start from 0");
        for (uint8 i = 0; i < _standardParcelPrices.length; i += 2) {
            uint256 standardParcelSoldCount = _standardParcelPrices[i];
            uint256 standardParcelPrice = _standardParcelPrices[i + 1];
            soldCountToStandardParcelPriceMapping[standardParcelSoldCount] = standardParcelPrice;
        }
        for (uint8 i = 0; i < _businessParcelPrices.length; i += 2) {
            uint256 businessParcelSoldCount = _businessParcelPrices[i];
            uint256 businessParcelPrice = _businessParcelPrices[i + 1];
            soldCountToBusinessParcelPriceMapping[businessParcelSoldCount] = businessParcelPrice;
        }
        emit ParcelsSoldCountPricingSet(_standardParcelPrices, _businessParcelPrices);
    }

    /// @notice Update bundles
    function setBundles(BundleInfo[13] calldata _bundles) external onlyOwner notZeroAddress {
        newBundles = _bundles;
        emit BundlesSet(_bundles);
    }

    /// @notice Set Super Bundles
    function setSuperBundles(SuperBundleInfo[4] calldata _bundles) external onlyOwner notZeroAddress {
        superBundlesInfos = _bundles;
        emit SuperBundlesSet(_bundles);
    }

    /// @notice Set contract addresses for all NFTs we currently have
    function setNFTContractAddresses(address[9] calldata _nftContractAddresses) external onlyOwner {
        standardParcelNFTAddress = _nftContractAddresses[0];
        businessParcelNFTAddress = _nftContractAddresses[1];
        minerV1NFTAddress = _nftContractAddresses[2];
        miningAddress = _nftContractAddresses[3];
        busdAddress = _nftContractAddresses[4];
        netGymStreetAddress = _nftContractAddresses[5];
        minerPublicBuildingAddress = _nftContractAddresses[6];
        signatureValidatorAddress = _nftContractAddresses[7];
        amountsDistributorAddress = _nftContractAddresses[8];
        emit NFTContractAddressesSet(_nftContractAddresses);
    }
    
    /// @notice Set the number of slots available for the miners for standard and upgraded parcels
    function setParcelsSlotsCount(uint8[2] calldata _parcelsSlotsCount) external onlyOwner {
        standardParcelSlotsCount = _parcelsSlotsCount[0];
        upgradedParcelSlotsCount = _parcelsSlotsCount[1];

        emit ParcelsSlotsCountSet(_parcelsSlotsCount[0], _parcelsSlotsCount[1]);
    }

    /// @notice Set the prices for all different entities we currently sell
    function setPurchasePrices(uint256[4] calldata _purchasePrices) external onlyOwner {
        upgradePrice = _purchasePrices[0];
        minerPrice = _purchasePrices[1];
        minerRepairPrice = _purchasePrices[2];
        electricityVoucherPrice = _purchasePrices[3];

        emit PurchasePricesSet(
            _purchasePrices[0],
            _purchasePrices[1],
            _purchasePrices[2],
            _purchasePrices[3]
        );
    }

    /// @notice Activate/Deactivate sales
    function setSaleActivation(bool _saleActivation) external onlyOwner {
        isSaleActive = _saleActivation;
        emit SaleActivationSet(_saleActivation);
    }

    function setBasicBundlesActivation(bool _activation) external onlyOwner {
        basicBundleActivated = _activation;
        emit BasicBundleActivationSet(_activation);
    }

    // @notice (Purchase) Generic minting functionality for parcels, regardless the currency
    function mintParcels(ParcelsMintSignature calldata _mintingSignature, uint256 _referrerId)
        external
        onlySaleActive
        notZeroAddress
    {
        require(ISignatureValidator(signatureValidatorAddress).verifySigner(_mintingSignature), "Municipality: Not authorized signer");
        uint256 parcelsLength = _mintingSignature.parcels.length;
        require(parcelsLength > 0, "Municipality: Can not mint 0 parcels");
        INetGymStreet(netGymStreetAddress).addGymMlm(msg.sender, _referrerId);
        uint256 price = _getUserPriceForParcels(msg.sender, parcelsLength);
        if(price > 0) {
            _transferToContract(price);
            IAmountsDistributor(amountsDistributorAddress).distributeAmounts(price, OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS, msg.sender);
            userToPurchasedAmountMapping[msg.sender] += price;
            _updateAdditionLevel(msg.sender);
            lastPurchaseData[msg.sender].dollarValue += price;
            _lastPurchaseDateUpdate(msg.sender);
            usersMintableNFTAmounts[msg.sender].parcels = 0;
        } else {
            usersMintableNFTAmounts[msg.sender].parcels -= parcelsLength;
        }
        IParcelInterface(standardParcelNFTAddress).mintParcels(msg.sender, _mintingSignature.parcels);
        currentlySoldStandardParcelsCount += parcelsLength;
    }

    // @notice (Purchase) Mint the given amount of miners
    function mintMiners(uint256 _count, uint256 _referrerId) external onlySaleActive notZeroAddress returns(uint256, uint256)
    {
        require(_count > 0, "Municipality: Can not mint 0 miners");
        INetGymStreet(netGymStreetAddress).addGymMlm(msg.sender, _referrerId);
        uint256 price = _getUserPriceForMiners(msg.sender, _count);
        if(price > 0) {
            _transferToContract(price);
            userToPurchasedAmountMapping[msg.sender] += price;
            _updateAdditionLevel(msg.sender);
            lastPurchaseData[msg.sender].dollarValue += price;
            _lastPurchaseDateUpdate(msg.sender);
            IAmountsDistributor(amountsDistributorAddress).distributeAmounts(price, OPERATION_TYPE_MINT_MINERS, msg.sender);
            usersMintableNFTAmounts[msg.sender].miners = 0;
        } else {
            usersMintableNFTAmounts[msg.sender].miners -= _count;
        }
        return IMinerNFT(minerV1NFTAddress).mintMiners(msg.sender, _count);
    }

    function purchaseBasicBundle(uint8 _bundleType, ParcelsMintSignature calldata _mintingSignature,
        uint256 _referrerId) external onlySaleActive notZeroAddress
    {
        require(basicBundleActivated, "Municipality: Basic bundle is deactivated");
        _validateBasicBundleType(_bundleType);
        _requireOnlyStandardParcels(_mintingSignature.parcels);
        require(ISignatureValidator(signatureValidatorAddress).verifySigner(_mintingSignature), "Municipality: Not authorized signer");
        BundleInfo memory bundle = newBundles[_bundleType];
        require(_mintingSignature.parcels.length == bundle.parcelsAmount, "Municipality: Invalid parcels amount");
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        INetGymStreet(netGymStreetAddress).addGymMlm(msg.sender, _referrerId);
        (uint256 parcelPrice, ) = _getPriceForParcels(bundle.parcelsAmount);
        uint256 bundlePrice = parcelPrice + bundle.minersAmount * minerPrice;
        uint256 bundlePurchasePrice = _discountPrice(bundlePrice, bundle.discountPct);
        _transferToContract(bundlePurchasePrice);
        userToPurchasedAmountMapping[msg.sender] += bundlePurchasePrice;
        _updateAdditionLevel(msg.sender);
        lastPurchase.dollarValue += bundlePurchasePrice;
        _lastPurchaseDateUpdate(msg.sender);
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(
            bundlePurchasePrice,
            OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS,
            msg.sender
        );
        uint256[] memory parcelIds = IMinerPublicBuildingInterface(minerPublicBuildingAddress).mintParcelsBundle(msg.sender, _mintingSignature.parcels);
        (uint256 minerIdPair0, uint256 minerIdPair1) = IMinerPublicBuildingInterface(minerPublicBuildingAddress).mintMinersBundle(msg.sender, bundle.minersAmount);
        uint256[] memory minerIds = new uint256[](minerIdPair1);
        uint256 index = 0;
        for(uint256 minerId = minerIdPair0; minerId < minerIdPair0 + minerIdPair1; minerId++) {
            minerIds[index] = minerId;
            index++;
        }
        _automaticallyAttachMinersToParcels(parcelIds, minerIds, minerIds.length);
        currentlySoldStandardParcelsCount += bundle.parcelsAmount;
        emit BundlePurchased(msg.sender, _bundleType);
    }

    function purchaseSuperBundle(uint8 _bundleType, uint256 _referrerId) external onlySaleActive notZeroAddress
    {
        _validateSuperBundleType(_bundleType);
        SuperBundleInfo memory bundle = superBundlesInfos[_bundleType - BUNDLE_TYPE_SUPER_1];
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        INetGymStreet(netGymStreetAddress).addGymMlm(msg.sender, _referrerId);
        uint256 bundlePurchasePrice = _getPriceForSuperBundle(_bundleType);
        _transferToContract(bundlePurchasePrice);
        userToPurchasedAmountMapping[msg.sender] += bundlePurchasePrice;
        _updateAdditionLevel(msg.sender);
        lastPurchase.dollarValue += bundlePurchasePrice;
        _lastPurchaseDateUpdate(msg.sender);
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(
            bundlePurchasePrice,
            OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS,
            msg.sender
        );
        userToElectricityVoucherAmountMapping[msg.sender] +=  bundle.vouchersAmount;
        usersMintableNFTAmounts[msg.sender].parcels += bundle.parcelsAmount;
        usersMintableNFTAmounts[msg.sender].upgrades += bundle.upgradesAmount;
        usersMintableNFTAmounts[msg.sender].miners += bundle.minersAmount;
        emit SuperBundlePurchased(msg.sender, _bundleType);
    }

    function purchaseParcelsBundle(uint8 _bundleType, ParcelsMintSignature calldata _mintingSignature,
        uint256 _referrerId) external onlySaleActive notZeroAddress
    {
        require(basicBundleActivated, "Municipality: Basic bundle is deactivated");
        _validateParcelsBundleType(_bundleType);
        _requireOnlyStandardParcels(_mintingSignature.parcels);
        require(ISignatureValidator(signatureValidatorAddress).verifySigner(_mintingSignature), "Municipality: Not authorized signer");
        BundleInfo memory bundle = newBundles[_bundleType];
        require(_mintingSignature.parcels.length == bundle.parcelsAmount, "Municipality: Invalid parcels amount");
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        INetGymStreet(netGymStreetAddress).addGymMlm(msg.sender, _referrerId);
        (uint256 price, ) = _getPriceForParcels(bundle.parcelsAmount);
        uint256 bundlePurchasePrice = _discountPrice(price, bundle.discountPct);
        _transferToContract(bundlePurchasePrice);
        userToPurchasedAmountMapping[msg.sender] += bundlePurchasePrice;
        _updateAdditionLevel(msg.sender);
        lastPurchase.dollarValue += bundlePurchasePrice;
        _lastPurchaseDateUpdate(msg.sender);
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(
            bundlePurchasePrice,
            OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS,
            msg.sender
        );
        IMinerPublicBuildingInterface(minerPublicBuildingAddress).mintParcelsBundle(msg.sender, _mintingSignature.parcels);
        currentlySoldStandardParcelsCount += bundle.parcelsAmount;
        emit BundlePurchased(msg.sender, _bundleType);
    }

    function purchaseMinersBundle(uint8 _bundleType, uint256 _referrerId) external onlySaleActive notZeroAddress returns(uint256, uint256) {
        require(basicBundleActivated, "Municipality: Basic bundle is deactivated");        
        _validateMinersBundleType(_bundleType);
        INetGymStreet(netGymStreetAddress).addGymMlm(msg.sender, _referrerId);
        BundleInfo memory bundle = newBundles[_bundleType];
        uint256 bundlePurchasePrice = _discountPrice(bundle.bundlePrice, bundle.discountPct);
        _transferToContract(bundlePurchasePrice);
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        userToPurchasedAmountMapping[msg.sender] += bundlePurchasePrice;
        _updateAdditionLevel(msg.sender);
        lastPurchase.dollarValue += bundlePurchasePrice;
        _lastPurchaseDateUpdate(msg.sender);
        uint256 minersAmount = bundle.minersAmount;
        uint256 minersPurchasePrice = _discountPrice(minersAmount * minerPrice, bundle.discountPct);
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(minersPurchasePrice, OPERATION_TYPE_MINT_MINERS, msg.sender);
        (uint256 firstMinerId, uint256 count) = IMinerPublicBuildingInterface(minerPublicBuildingAddress).mintMinersBundle(msg.sender, minersAmount);
        emit BundlePurchased(msg.sender, _bundleType);
        return (firstMinerId, count);
    }

    // granting free Parcels to selected user 
    function grantParcels(ParcelsMintSignature calldata _mintingSignature,
        uint256 _referrerId, address _user) external onlyOwner {
        require(_mintingSignature.parcels.length <= 240, "Municipality: The amount of miners should be less or equal to 240");
        _requireOnlyStandardParcels(_mintingSignature.parcels);
        require(ISignatureValidator(signatureValidatorAddress).verifySigner(_mintingSignature), "Municipality: Not authorized signer");
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);
        IParcelInterface(standardParcelNFTAddress).mintParcels(_user, _mintingSignature.parcels);
        currentlySoldStandardParcelsCount += _mintingSignature.parcels.length;
    }

    // granting free Miners to selected user
    function grantMiners(uint8 _minersAmount, uint256 _referrerId, address _user) external onlyOwner returns(uint256, uint256) {
        require(_minersAmount <= 240, "Municipality: The amount of miners should be less than or equal to 240");
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);
        (uint256 firstMinerId, uint256 count) = IMinerNFT(minerV1NFTAddress).mintMiners(_user, _minersAmount);
        return (firstMinerId, count);
    }

    // @notice (Purchase) Purchase a given amount of el. vouchers
    function purchaseVouchers(uint16 count) external onlySaleActive notZeroAddress {
        uint256 _amount = count * electricityVoucherPrice;
        _transferToContract(_amount);
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(_amount, OPERATION_TYPE_PURCHASE_ELECTRICITY, msg.sender);
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        userToElectricityVoucherAmountMapping[msg.sender] += count;
        userToPurchasedAmountMapping[msg.sender] += _amount;
        _updateAdditionLevel(msg.sender);
        lastPurchase.dollarValue += _amount;
        _lastPurchaseDateUpdate(msg.sender);
        emit VouchersPurchased(msg.sender, count);
    }

    // @notice (Purchase) Repair ALL miners - reset the amortization points in the mining SC.
    function repairAllMiners() external onlySaleActive notZeroAddress {
        uint256 minersCount = IMining(miningAddress).getMinersCount(msg.sender);
        uint256 _amount = minersCount * minerRepairPrice;
        _transferToContract(_amount);
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(_amount, OPERATION_TYPE_PURCHASE_REPAIR, msg.sender);
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        userToRepairDatesMapping[msg.sender].push(block.timestamp);
        userToPurchasedAmountMapping[msg.sender] += _amount;
        _updateAdditionLevel(msg.sender);
        lastPurchase.dollarValue += _amount;
        _lastPurchaseDateUpdate(msg.sender);
        IMining(miningAddress).repairMiners(msg.sender);
        emit MinersRepaired(msg.sender, minersCount);
    }

    // @notice Apply a voucher from the user's balance to a selected miner
    // We won't use the amount of vouchers to be used in this function.  
    // But just to keep things consistent with the Back/Front ends we will keep the arguments the same
    function applyVoucher(uint256, uint256[] memory minerIds) external notZeroAddress {
        uint256 numAvailableVouchers = userToElectricityVoucherAmountMapping[msg.sender];
        require(
            numAvailableVouchers >= minerIds.length,
            "Municipality: Not enough vouchers on balance"
        );
        userToElectricityVoucherAmountMapping[msg.sender] = numAvailableVouchers - minerIds.length;
        IMining(miningAddress).applyVouchers(msg.sender, minerIds);
        emit VouchersApplied(msg.sender, minerIds);
    }

    // @notice Attach/Detach the miners
    function attachDetachMinersToParcel(uint256[] calldata minersToAttach, uint256 parcelId) external notZeroAddress {
        require(IERC721Base(standardParcelNFTAddress).exists(parcelId), "Municipality: Parcel doesnt exist");
        _requireMinersCountMatchingWithParcelSlots(parcelId, minersToAttach.length);
        require(
            IERC721Base(standardParcelNFTAddress).ownerOf(parcelId) == msg.sender,
            "Municipality: Invalid parcel owner"
        );
        IMinerNFT(minerV1NFTAddress).requireNFTsBelongToUser(minersToAttach, msg.sender);
        _attachDetachMinersToParcel(minersToAttach, parcelId);
    }

    /// @notice Used by MinerPublicBuilding to attach miner to a parcel
    function attachMinerToParcel(address user, uint256 firstMinerId, uint256[] calldata parcelIds) external onlyMinerPublicBuilding {
        uint32 minerCounter = 0;
        for (uint16 i = 0; i < parcelIds.length; i++) {
            for (uint16 j = 0; j < 4; j++) {
                minerParcelMapping[firstMinerId + minerCounter] = parcelIds[i];
                parcelMinersMapping[parcelIds[i]].push(firstMinerId + minerCounter);
                minerCounter++;
                emit MinerAttached(user, parcelIds[i], firstMinerId + minerCounter);
            }
        }
    }

    /// @notice Upgrade a group of standard parcels
    function upgradeStandardParcelsGroup(uint256[] memory _parcelIds) external onlySaleActive {
        uint256 _totalUpgradePrice = _parcelIds.length * upgradePrice;
        for(uint256 i = 0; i < _parcelIds.length; ++i) {
            require(
                IERC721Base(standardParcelNFTAddress).ownerOf(_parcelIds[i]) == msg.sender,
                "Municipality: Invalid NFT owner"
            );
            require(!IParcelInterface(standardParcelNFTAddress).isParcelUpgraded(_parcelIds[i]),
                "Municipality: Parcel is already upgraded");
            if(usersMintableNFTAmounts[msg.sender].upgrades > 0) {
                usersMintableNFTAmounts[msg.sender].upgrades--;
                _totalUpgradePrice -= upgradePrice;
            }
        }
        if(_totalUpgradePrice > 0) {
            _transferToContract(_totalUpgradePrice);
            IAmountsDistributor(amountsDistributorAddress).distributeAmounts(_totalUpgradePrice, OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS, msg.sender);
            LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
            userToPurchasedAmountMapping[msg.sender] += _totalUpgradePrice;
            _updateAdditionLevel(msg.sender);
            lastPurchase.dollarValue += _totalUpgradePrice;
            _lastPurchaseDateUpdate(msg.sender);
        }
        IParcelInterface(standardParcelNFTAddress).upgradeParcels(_parcelIds);
    }

    /// @notice Upgrade the standard parcel
    function upgradeStandardParcel(uint256 _parcelId) external onlySaleActive {
        require(
            IERC721Base(standardParcelNFTAddress).ownerOf(_parcelId) == msg.sender,
            "Municipality: Invalid NFT owner"
        );
        bool isParcelUpgraded = IParcelInterface(standardParcelNFTAddress).isParcelUpgraded(_parcelId);
        require(!isParcelUpgraded, "Municipality: Parcel is already upgraded");
        if(usersMintableNFTAmounts[msg.sender].upgrades > 0) {
            usersMintableNFTAmounts[msg.sender].upgrades--;
        } else {
            _transferToContract(upgradePrice);
            IAmountsDistributor(amountsDistributorAddress).distributeAmounts(upgradePrice, OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS, msg.sender);
            LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
            userToPurchasedAmountMapping[msg.sender] += upgradePrice;
            _updateAdditionLevel(msg.sender);
            lastPurchase.dollarValue += upgradePrice;
            _lastPurchaseDateUpdate(msg.sender);
        }
        IParcelInterface(standardParcelNFTAddress).upgradeParcel(_parcelId);
    }

    function getPriceForSuperBundle(uint8 _bundleType) external view returns(uint256) {
        return _getPriceForSuperBundle(_bundleType);
    }

    function getUserPriceForParcels(address _user, uint256 _parcelsCount) external view returns(uint256) {
        return(_getUserPriceForParcels(_user, _parcelsCount));
    }

    function getUserPriceForMiners(address _user, uint256 _minersCount) external view returns(uint256) {
        return(_getUserPriceForMiners(_user, _minersCount));
    }
    // @notice App will use this function to get the price for the selected parcels
    function getPriceForParcels(Parcel[] calldata parcels) external view returns (uint256, uint256) {
        (uint256 price, uint256 unitPrice) = _getPriceForParcels(parcels.length);
        return (price, unitPrice);
    }
    
    function getUserMiners(address _user) external view returns (AttachedMiner[] memory) {
        uint256[] memory userMiners = IERC721Base(minerV1NFTAddress).tokensOf(_user);
        AttachedMiner[] memory result = new AttachedMiner[](userMiners.length);
        for (uint256 i = 0; i < userMiners.length; ++i) {
            uint256 minerId = userMiners[i];
            uint256 parcelId = minerParcelMapping[minerId];
            result[i] = AttachedMiner(parcelId, minerId);
        }
        return result;
    }
    // TODO: This function should be removed after 30 days from upgrade as the expiration date is in mapping lastPurchaseData
    function getNFTPurchaseExpirationDate(address _user) external view returns(uint256) {
        if(lastPurchaseData[_user].expirationDate > (INetGymStreet(netGymStreetAddress).lastPurchaseDateERC(_user) + 30 days)) {
            return lastPurchaseData[_user].expirationDate;
        } else {
            return INetGymStreet(netGymStreetAddress).lastPurchaseDateERC(_user) + 30 days;
        } 
    }

    function isTokenLocked(address _tokenAddress, uint256 _tokenId) external view returns(bool) { 
        if(_tokenAddress == minerV1NFTAddress) {
            return minerParcelMapping[_tokenId] > 0;
        } else if(_tokenAddress == standardParcelNFTAddress) {
            return parcelMinersMapping[_tokenId].length > 0;
        } else {
            revert("Municipality: Unsupported NFT token address");
        }
    }

    /// @notice automatically attach free miners to parcels
    function automaticallyAttachMinersToParcels(uint256 numMiners) external {
        _automaticallyAttachMinersToParcels(
            IERC721Base(standardParcelNFTAddress).tokensOf(msg.sender),
            IERC721Base(minerV1NFTAddress).tokensOf(msg.sender),
            numMiners);
    }

    function _getPriceForSuperBundle(uint8 _bundleType) private view returns(uint256) {
        _validateSuperBundleType(_bundleType);
        SuperBundleInfo memory bundle = superBundlesInfos[_bundleType- BUNDLE_TYPE_SUPER_1];
        (uint256 parcelPrice, ) = _getPriceForParcels(bundle.parcelsAmount);
        uint256 bundlePrice = parcelPrice + bundle.minersAmount * minerPrice;
        return _discountPrice(bundlePrice, bundle.discountPct);
    }

    function _getUserPriceForParcels(address _user, uint256 _parcelsCount) private view returns(uint256) {
        if(usersMintableNFTAmounts[_user].parcels >= _parcelsCount)
            return 0;
        else {
            uint256 unpaidCount = _parcelsCount - usersMintableNFTAmounts[_user].parcels;
            (uint256 price,) = _getPriceForParcels(unpaidCount);
            uint256 percentage;
            if(unpaidCount >= 90) {
                percentage = 35187;
            } else if(unpaidCount >= 35) {
                percentage = 28577;
            } else if(unpaidCount >= 16) {
                percentage = 21875;
            } else if(unpaidCount >= 3) {
                percentage = 16667;
            }
            uint256 discountedPrice = _discountPrice(price, percentage);
            return discountedPrice;
        }
    }

    function _getUserPriceForMiners(address _user, uint256 _minersCount) private view returns(uint256) {
        if(usersMintableNFTAmounts[_user].miners >= _minersCount)
            return 0;
        else {
            uint256 unpaidCount = _minersCount - usersMintableNFTAmounts[_user].miners;
            uint256 price = unpaidCount * minerPrice;
            uint256 percentage;
            if(unpaidCount >= 90) {
                percentage = 35187;
            } else if(unpaidCount >= 35) {
                percentage = 28577;
            } else if(unpaidCount >= 16) {
                percentage = 21875;
            } else if(unpaidCount >= 3) {
                percentage = 16667;
            }
            uint256 discountedPrice = _discountPrice(price, percentage);
            return discountedPrice;
        }
    }

    

    // @notice Private interface

    function _automaticallyAttachMinersToParcels(uint256[] memory parcelIds, uint256[] memory userMiners, uint256 numMiners) private {
        uint256 lastAvailableMinerIndex = 0;
        for(uint256 i = 0; i < parcelIds.length && lastAvailableMinerIndex < userMiners.length && numMiners > 0; ++i) {
            uint256 availableSize = IParcelInterface(standardParcelNFTAddress).isParcelUpgraded(parcelIds[i]) ?
                upgradedParcelSlotsCount - parcelMinersMapping[parcelIds[i]].length :
                standardParcelSlotsCount - parcelMinersMapping[parcelIds[i]].length;
            if(availableSize > 0) {
                for(uint256 j = 0; j < availableSize; ++j) {
                    if(numMiners != 0) {
                        for(uint256 k = lastAvailableMinerIndex; k < userMiners.length; ++k) {
                            lastAvailableMinerIndex = k + 1;
                            if(minerParcelMapping[userMiners[k]] == 0) {
                                parcelMinersMapping[parcelIds[i]].push(userMiners[k]);
                                minerParcelMapping[userMiners[k]] = parcelIds[i];
                                IMining(miningAddress).deposit(msg.sender, userMiners[k], 1000);
                                emit MinerAttached(msg.sender, parcelIds[i], userMiners[k]);
                                --numMiners;
                                break;
                            }
                        }

                    }
                }
            }
        }
    }

    /// @notice Transfers the given BUSD amount to distributor contract
    function _transferToContract(uint256 _amount) private {
        IERC20Upgradeable(busdAddress).safeTransferFrom(
            address(msg.sender),
            address(amountsDistributorAddress),
            _amount
        );
    }

    /// @notice Checks if the miner is in the given list
    function _isMinerInList(uint256 _tokenId, uint256[] memory _minersList) private pure returns (bool) {
        for (uint256 index; index < _minersList.length; index++) {
            if (_tokenId == _minersList[index]) {
                return true;
            }
        }
        return false;
    }

    /// @notice Validates if the bundle corresponds to a type from this smart contract
    function _validateBasicBundleType(uint8 _bundleType) private pure {
        require
        (
            _bundleType == BUNDLE_TYPE_PARCELS_MINERS_1,
            "Municipality: Invalid bundle type"
        );
    }
    function _validateSuperBundleType(uint8 _bundleType) private pure {
        require
        (
            _bundleType == BUNDLE_TYPE_SUPER_1 ||
            _bundleType == BUNDLE_TYPE_SUPER_2 ||
            _bundleType == BUNDLE_TYPE_SUPER_3 ||
            _bundleType == BUNDLE_TYPE_SUPER_4,
            "Municipality: Invalid super bundle type"
        );
    }

    function _validateParcelsBundleType(uint8 _bundleType) private pure {
        require
        (
            _bundleType == BUNDLE_TYPE_PARCELS_1 ||
            _bundleType == BUNDLE_TYPE_PARCELS_2 ||
            _bundleType == BUNDLE_TYPE_PARCELS_3 ||
            _bundleType == BUNDLE_TYPE_PARCELS_4 ||
            _bundleType == BUNDLE_TYPE_PARCELS_5 ||
            _bundleType == BUNDLE_TYPE_PARCELS_6,
            "Municipality: Invalid bundle type"
        );
    }

    /// @notice Validates if the bundle corresponds to a type from this smart contract
    function _validateMinersBundleType(uint8 _bundleType) private pure {
        require
        (
            _bundleType == BUNDLE_TYPE_MINERS_1 ||
            _bundleType == BUNDLE_TYPE_MINERS_2 ||
            _bundleType == BUNDLE_TYPE_MINERS_3 ||
            _bundleType == BUNDLE_TYPE_MINERS_4 ||
            _bundleType == BUNDLE_TYPE_MINERS_5 ||
            _bundleType == BUNDLE_TYPE_MINERS_6,
            "Municipality: Invalid bundle type"
        );
    }

    /// @notice Requires that only a standard parcel can perform the operation
    function _requireOnlyStandardParcels(Parcel[] memory parcels) private pure {
        for(uint256 index; index < parcels.length; index++) {
            require(
                parcels[index].parcelType == PARCEL_TYPE_STANDARD,
                "Municipality: Parcel does not have standard type"
            );
        }
    }

    /// @notice Requires the miner status to match with the given by a function argument status
    function _requireMinerStatus(uint256 miner, uint8 status, uint256 attachedParcelId) private view {
        if (status == MINER_STATUS_ATTACHED) {
            require(minerParcelMapping[miner] == attachedParcelId, "Municipality: Miner not attached to this parcel");
        } else if (status == MINER_STATUS_DETACHED) {
            uint256 attachedParcel = minerParcelMapping[miner];
            require(attachedParcel == 0, "Municipality: Miner is not detached");
        }
    }

    /// @notice Attach or detach the miners from/to parcel
    function _attachDetachMinersToParcel(uint256[] memory newMiners, uint256 parcelId) private {
        uint256[] memory oldMiners = parcelMinersMapping[parcelId];
        for (uint256 index; index < oldMiners.length; index++) {
            uint256 tokenId = oldMiners[index];
            if (!_isMinerInList(tokenId, newMiners)) {
                _requireMinerStatus(tokenId, MINER_STATUS_ATTACHED, parcelId);
                minerParcelMapping[tokenId] = 0;
                IMining(miningAddress).withdraw(msg.sender,tokenId);
                emit MinerDetached(msg.sender, parcelId, tokenId);
            }
        }
        uint256 minerHashrate = IMinerNFT(minerV1NFTAddress).hashrate();
        for (uint256 index; index < newMiners.length; index++) {
            uint256 tokenId = newMiners[index];
            if (!_isMinerInList(tokenId, oldMiners)) {
                _requireMinerStatus(tokenId, MINER_STATUS_DETACHED, parcelId);
                minerParcelMapping[tokenId] = parcelId;
                IMining(miningAddress).deposit(msg.sender, tokenId, minerHashrate);
                emit MinerAttached(msg.sender, parcelId, tokenId);
            }
        }
        parcelMinersMapping[parcelId] = newMiners;
    }

    /// @notice Require that the count of the miners match with the slots that are on a parcel (4 or 10)
    function _requireMinersCountMatchingWithParcelSlots(uint256 _parcelId, uint256 _count)
        private
        view
    {
        bool isParcelUpgraded = IParcelInterface(standardParcelNFTAddress).isParcelUpgraded(_parcelId);
        require(
            isParcelUpgraded
                ? _count <= upgradedParcelSlotsCount
                : _count <= standardParcelSlotsCount,
            "Municipality: Miners count exceeds parcel's slot count"
        );
    }

    /// @notice Returns the price of a given parcels
    function _getPriceForParcels(uint256 parcelsCount) private view returns (uint256, uint256) {
        uint256 price = parcelsCount * 100000000000000000000;
        uint256 unitPrice = 100000000000000000000;
        uint256 priceBefore = 0;
        uint256 totalParcelsToBuy = currentlySoldStandardParcelsCount + parcelsCount;
        if(totalParcelsToBuy > 157500) {
            unitPrice = 301000000000000000000;
            if (currentlySoldStandardParcelsCount > 157500) {
                price = parcelsCount * 301000000000000000000;
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 157500) * 301000000000000000000;
                priceBefore = (157500 - currentlySoldStandardParcelsCount) * 209000000000000000000;
            }
        } else if(totalParcelsToBuy > 105000) {
            unitPrice = 209000000000000000000;
             if (currentlySoldStandardParcelsCount > 105000) {
                price = parcelsCount * 209000000000000000000;
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 105000) * 209000000000000000000;
                priceBefore = (105000 - currentlySoldStandardParcelsCount) * 144000000000000000000;
            }
        } else if(totalParcelsToBuy > 52500) {
            unitPrice = 144000000000000000000;
            if (currentlySoldStandardParcelsCount > 52500) {
                price = parcelsCount * 144000000000000000000;
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 52500) * 144000000000000000000;
                priceBefore = (52500 - currentlySoldStandardParcelsCount) * 116000000000000000000;
            }
        } else if(totalParcelsToBuy > 21000) {
             unitPrice = 116000000000000000000;
            if (currentlySoldStandardParcelsCount > 21000) {
                price = parcelsCount * 116000000000000000000; 
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 21000) * 116000000000000000000;
                priceBefore = (21000 - currentlySoldStandardParcelsCount) * 100000000000000000000;
            }
            
        }
        return (priceBefore + price, unitPrice);
    }

    /// @notice Returns the discounted price of the bundle
    function _discountPrice(uint256 _price, uint256 _percentage) private pure returns (uint256) {
        return _price - (_price * _percentage) / 100000;
    }

     /**
     * @notice Private function to update additional level in GymStreet
     * @param _user: user address
     */
    function _updateAdditionLevel(address _user) private {
        uint256 _additionalLevel;
        (uint256 termTimestamp, uint256 _gymLevel) = INetGymStreet(netGymStreetAddress).getInfoForAdditionalLevel(_user);
        if (termTimestamp + 2505600 > block.timestamp){ // 30 days
            if (userToPurchasedAmountMapping[_user] >= 17500 * 1e18) {
                _additionalLevel = 21;
            } else if (userToPurchasedAmountMapping[_user] >= 7500 * 1e18) {
                _additionalLevel = 14;
            } else if (userToPurchasedAmountMapping[_user] >= 3750 * 1e18) {
                _additionalLevel = 9;
            } else if (userToPurchasedAmountMapping[_user] >= 750 * 1e18) {
                _additionalLevel = 5;
            }

            if (_additionalLevel > _gymLevel) {
            INetGymStreet(netGymStreetAddress).updateAdditionalLevel(_user, _additionalLevel);
            }
        }
    }

    function updateUserLevel(address _user) private {
        if(userToPurchasedAmountMapping[_user] < 750 * 1e18) {
            INetGymStreet(netGymStreetAddress).updateUserLevel(_user, userToPurchasedAmountMapping[_user]);
        }
    }

    /**
     * @notice Private function to update last purchase date
     * @param _user: user address
     */
    function _lastPurchaseDateUpdate(address _user) private {
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];
        uint256 _lastDate = INetGymStreet(netGymStreetAddress).lastPurchaseDateERC(_user);
        lastPurchase.lastPurchaseDate = block.timestamp;
        if (lastPurchase.expirationDate < _lastDate + 30 days) {
            lastPurchase.expirationDate = _lastDate + 30 days;
        }
        if(lastPurchase.expirationDate < block.timestamp) {
            lastPurchase.expirationDate = lastPurchase.lastPurchaseDate;
        }
        if (lastPurchase.dollarValue >= (100 * 1e18)) {
            lastPurchase.expirationDate = lastPurchase.lastPurchaseDate + 30 days;
            lastPurchase.dollarValue = 0;     
        }
        updateUserLevel(_user);

    }

}