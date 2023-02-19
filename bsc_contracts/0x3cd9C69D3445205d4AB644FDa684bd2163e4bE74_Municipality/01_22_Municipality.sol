// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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

    struct UserMintableNFTAmounts {
        uint256 parcels;
        uint256 miners;
        uint256 upgrades;
    }

    uint8 private constant OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS = 10;
    uint8 private constant OPERATION_TYPE_MINT_MINERS = 20;

    uint8 private constant MINER_STATUS_DETACHED = 10;
    uint8 private constant MINER_STATUS_ATTACHED = 20;

    uint8 private constant PARCEL_TYPE_STANDARD = 10;
    // uint8 private constant PARCEL_TYPE_BUSINESS = 20;

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

    uint8 private constant PURCHASE_TYPE_MINER = 0;
    uint8 private constant PURCHASE_TYPE_PARCEL = 1;
    uint8 private constant PURCHASE_TYPE_BUNDLE = 2;
    uint8 private constant PURCHASE_TYPE_SUPER_BUNDLE = 3;
    uint8 private constant PURCHASE_TYPE_MINERS_BUNDLE = 5;
    uint8 private constant PURCHASE_TYPE_PARCELS_BUNDLE = 6;
    uint8 private constant PURCHASE_TYPE_UPGRADE_STANDARD_PARCEL = 7;
    uint8 private constant PURCHASE_TYPE_UPGRADE_STANDARD_PARCELS_GROUP = 8;
    uint8 private constant PURCHASE_TYPE_PARCELS = 9;
    uint8 private constant PURCHASE_TYPE_MINERS = 10;

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
    address public web2BackendAddress;


    // ------------------------------------ EVENTS ------------------------------------ //

    // event ParcelsSoldCountPricingSet(uint256[] indexed standardParcelPrices);
    event BundlesSet(BundleInfo[13] indexed bundles);
    event SuperBundlesSet(SuperBundleInfo[4] indexed bundles);
    // event ParcelsSlotsCountSet(
    //     uint8 indexed standardParcelSlotsCount,
    //     uint8 indexed upgradedParcelSlotsCount
    // );
    // event SaleActivationSet(bool indexed saleActivation);
    event BundlePurchased(address indexed user, uint256 indexed bundleType);
    event SuperBundlePurchased(address indexed user, uint256 indexed bundleType);
    event MinerAttached(address user, uint256 indexed parcelId, uint256 indexed minerId);
    event MinerDetached(address indexed user, uint256 indexed parcelId, uint256 indexed minerId);
    // event NFTContractAddressesSet(address[9] indexed _nftContractAddresses);
    // event BasicBundleActivationSet(bool indexed _activation);
    event PurchaseMade(address indexed user, uint8 indexed purchaseType, uint256[] nftId, uint256 purchasePrice);
    event ParcelGranted(address indexed user, uint256 indexed count);
    event MinerGranted(address indexed user, uint256 indexed count);
    event UpgradeGranted(address indexed user, uint256 indexed count);
    event BalanceUpdated(address indexed user, uint256 parcelCount, uint256 minerCount, uint256 upgradeCount, bool isNegative);

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

    modifier onlyNetGymStreet() {
        require(msg.sender == netGymStreetAddress, "Municipality: This function is available only for NetGymStreeet");
        _;
    }
     
    modifier onlyWeb2Backend() {	
        require(msg.sender == web2BackendAddress, "Municipality: This function is available only for web2 backend");	
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
    function setParcelsSoldCountPricing(uint256[] calldata _standardParcelPrices) external onlyOwner notZeroAddress {
        require(_standardParcelPrices[0] == 0, "Municipality: The given standard parcel array must start from 0");
        for (uint8 i = 0; i < _standardParcelPrices.length; i += 2) {
            uint256 standardParcelSoldCount = _standardParcelPrices[i];
            uint256 standardParcelPrice = _standardParcelPrices[i + 1];
            soldCountToStandardParcelPriceMapping[standardParcelSoldCount] = standardParcelPrice;
        }
        // emit ParcelsSoldCountPricingSet(_standardParcelPrices);
    }

    /// @notice Update bundles
    function setBundles(BundleInfo[13] calldata _bundles) external onlyOwner notZeroAddress {
        newBundles = _bundles;
        emit BundlesSet(_bundles);
    }

    function getNewBundlesArray() external view returns(BundleInfo[13] memory) {
        return newBundles;
    }

    /// @notice Set Super Bundles
    function setSuperBundles(SuperBundleInfo[4] calldata _bundles) external onlyOwner notZeroAddress {
        superBundlesInfos = _bundles;
        emit SuperBundlesSet(_bundles);
    }

    function getSuperBundlesArray() external view returns(SuperBundleInfo[4] memory) {
        return superBundlesInfos;
    }

    function getBundles() external view returns (uint256[6][17] memory bundleStats) {
        BundleInfo[13] memory bundle = newBundles;
        SuperBundleInfo[4] memory superBundle = superBundlesInfos;
        for (uint8 i = 0; i < 17; i++) {
            if (i < 13) {
                (uint256 discountPrice, uint256 price) = _getPriceForBundle(i);
                bundleStats[i] = [i, bundle[i].parcelsAmount, bundle[i].minersAmount, 0, discountPrice, price];
            } else {
                (uint256 discountPrice, uint256 price) = _getPriceForSuperBundle(i);
                bundleStats[i] = [i, superBundle[i-13].parcelsAmount, superBundle[i-13].minersAmount, superBundle[i-13].upgradesAmount, discountPrice, price];
            }    
        }
    }

    /// @notice Set contract addresses for all NFTs we currently have
    /// @notice Get price for mintParcels and purchaseParcels for Gymnet use purposes
    /// returns  priceForMinting, priceForSinglePurchase, rawParcelsPrice
    function getPriceForPurchaseParcels (address _user, uint256 _parcelsCount) external view returns(uint256, uint256, uint256) {
        return _getPriceForPurchaseParcels (_user, _parcelsCount);
    }

    /// @notice Get price for mintMiners and purchaseMiners for Gymnet use purposes
    /// returns priceForMinting, priceForSinglePurchase, rawParcelsPrice
    function getPriceForPurchaseMiners(address _user, uint256 _minersCount) external view returns(uint256, uint256, uint256) {
        return _getPriceForPurchaseMiners(_user, _minersCount);
    }

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
        // emit NFTContractAddressesSet(_nftContractAddresses);
    }
    
    function setWeb2BackendAddress(address _web2BackendAddress) external onlyOwner {		
        web2BackendAddress = _web2BackendAddress;		
    }		

    /// @notice Set the number of slots available for the miners for standard and upgraded parcels
    function setParcelsSlotsCount(uint8[2] calldata _parcelsSlotsCount) external onlyOwner {
        standardParcelSlotsCount = _parcelsSlotsCount[0];
        upgradedParcelSlotsCount = _parcelsSlotsCount[1];

        // emit ParcelsSlotsCountSet(_parcelsSlotsCount[0], _parcelsSlotsCount[1]);
    }

    /// @notice Set the prices for all different entities we currently sell
    function setPurchasePrices(uint256[4] calldata _purchasePrices) external onlyOwner {
        upgradePrice = _purchasePrices[0];
        minerPrice = _purchasePrices[1];
        minerRepairPrice = _purchasePrices[2];
        electricityVoucherPrice = _purchasePrices[3];
    
    }

    /// @notice Activate/Deactivate sales
    function setSaleActivation(bool _saleActivation) external onlyOwner {
        isSaleActive = _saleActivation;
        // emit SaleActivationSet(_saleActivation);
    }

    function setBasicBundlesActivation(bool _activation) external onlyOwner {
        basicBundleActivated = _activation;
        // emit BasicBundleActivationSet(_activation);
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
        (uint256 price,,) = _getPriceForPurchaseParcels(msg.sender, parcelsLength);
        if(price > 0) {
            _transferToContract(price);
            IAmountsDistributor(amountsDistributorAddress).distributeAmounts(price, OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS, msg.sender);
            userToPurchasedAmountMapping[msg.sender] += price;
            _updateAdditionLevel(msg.sender);
            lastPurchaseData[msg.sender].dollarValue += price;
            _lastPurchaseDateUpdate(msg.sender);
            emit BalanceUpdated(msg.sender, usersMintableNFTAmounts[msg.sender].parcels, 0, 0, true);
            usersMintableNFTAmounts[msg.sender].parcels = 0;
        } else {
            usersMintableNFTAmounts[msg.sender].parcels -= parcelsLength;
            emit BalanceUpdated(msg.sender, parcelsLength, 0, 0, true);
        }
        uint256[] memory parcelIds = IParcelInterface(standardParcelNFTAddress).mintParcels(msg.sender, _mintingSignature.parcels);
        currentlySoldStandardParcelsCount += parcelsLength;
        if (price > 0) {
            emit PurchaseMade(msg.sender, PURCHASE_TYPE_PARCEL, parcelIds, price);
        }
       
    }

    // @notice (Purchase) Mint the given amount of miners
    function mintMiners(uint256 _count, uint256 _referrerId) external onlySaleActive notZeroAddress returns(uint256, uint256)
    {
        require(_count > 0, "Municipality: Can not mint 0 miners");
        INetGymStreet(netGymStreetAddress).addGymMlm(msg.sender, _referrerId);
        (uint256 price,,) = _getPriceForPurchaseMiners(msg.sender, _count);
        if(price > 0) {
            _transferToContract(price);
            userToPurchasedAmountMapping[msg.sender] += price;
            _updateAdditionLevel(msg.sender);
            lastPurchaseData[msg.sender].dollarValue += price;
            _lastPurchaseDateUpdate(msg.sender);
            IAmountsDistributor(amountsDistributorAddress).distributeAmounts(price, OPERATION_TYPE_MINT_MINERS, msg.sender);
            emit BalanceUpdated(msg.sender, 0, usersMintableNFTAmounts[msg.sender].miners, 0, true);
            usersMintableNFTAmounts[msg.sender].miners = 0;
        } else {
            usersMintableNFTAmounts[msg.sender].miners -= _count;
            emit BalanceUpdated(msg.sender, 0, _count, 0, true);
        }
        (uint256 firstMinerId, uint256 count) = IMinerNFT(minerV1NFTAddress).mintMiners(msg.sender, _count);
        uint256[] memory minerIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            minerIds[i] = firstMinerId + i;
        }
        if (price > 0) {
            emit PurchaseMade(msg.sender, PURCHASE_TYPE_MINER, minerIds, price);
        }
        
        return (firstMinerId, count);
    }

    ///@notice purchase Parcels balance (without minting) from Gymnet Side
    function purchaseParcels(uint256 _parcelsAmount, uint256 _referrerId) external onlySaleActive notZeroAddress {
        _purchaseParcels(_parcelsAmount, _referrerId, msg.sender);	
    }	

    ///@notice purchase Parcels balance (without minting) via Web2 	
    function web2PurchaseParcels(uint256 _parcelsAmount, uint256 _referrerId, address _user) external onlySaleActive onlyWeb2Backend {	
        _purchaseParcels(_parcelsAmount, _referrerId, _user);	
    }

    ///@notice purchase Miners balance (without minting) from Gymnet Side
    function purchaseMiners(uint256 _minersCount, uint256 _referrerId) external onlySaleActive notZeroAddress {
        _purchaseMiners(_minersCount, _referrerId, msg.sender);	
    }

    ///@notice purchase Miners balance (without minting) via Web2	
    function web2PurchaseMiners(uint256 _minersCount, uint256 _referrerId, address _user) external onlySaleActive onlyWeb2Backend {	
        _purchaseMiners(_minersCount, _referrerId, _user);	
    }

    function purchaseBasicBundle(uint8 _bundleType, uint256 _referrerId) external onlySaleActive notZeroAddress {
        _purchaseBasicBundle(_bundleType, _referrerId, msg.sender);	
    }	

    ///@notice purchase basic bundle via web2	
    function web2PurchaseBasicBundle(uint8 _bundleType, uint256 _referrerId, address _user) external onlySaleActive onlyWeb2Backend {	
        _purchaseBasicBundle(_bundleType, _referrerId, _user);	
    }

    function purchaseSuperBundle(uint8 _bundleType, uint256 _referrerId) external onlySaleActive notZeroAddress {
        _purchaseSuperBundle(_bundleType, _referrerId, msg.sender);	
    }	

    ///@notice purchase super bundle via web2	
    function web2PurchaseSuperBundle(uint8 _bundleType, uint256 _referrerId, address _user) external onlySaleActive onlyWeb2Backend {	
       _purchaseSuperBundle(_bundleType, _referrerId, _user);	
    }	

    function purchaseParcelsBundle(uint8 _bundleType, uint256 _referrerId) external onlySaleActive notZeroAddress {
        _purchaseParcelsBundle(_bundleType, _referrerId, msg.sender);	
    }

    function web2PurchaseParcelsBundle(uint8 _bundleType, uint256 _referrerId, address _user) external onlySaleActive onlyWeb2Backend {	
        _purchaseParcelsBundle(_bundleType, _referrerId, _user);	
    }

    function purchaseMinersBundle(uint8 _bundleType, uint256 _referrerId) external onlySaleActive notZeroAddress {
        _purchaseMinersBundle(_bundleType, _referrerId, msg.sender);	
    }	

    function web2PurchaseMinersBundle(uint8 _bundleType, uint256 _referrerId, address _user) external onlySaleActive onlyWeb2Backend {	
        _purchaseMinersBundle(_bundleType, _referrerId, _user);	
    }

    // granting free Parcels to selected user 
    function grantParcels(uint256 parcelsAmount, uint256 _referrerId, address _user) external onlyOwner {
        if(_referrerId != 0) {
            INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);
        }
        usersMintableNFTAmounts[_user].parcels += parcelsAmount;
        emit ParcelGranted(_user, parcelsAmount);
        emit BalanceUpdated(_user, parcelsAmount, 0, 0, false);
    }

    // granting free Miners to selected user
    function grantMiners(uint256 _minersAmount, uint256 _referrerId, address _user) external onlyOwner {
        if(_referrerId != 0) {
            INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);
        }
        usersMintableNFTAmounts[_user].miners += _minersAmount;
        emit MinerGranted(_user, _minersAmount);
        emit BalanceUpdated(_user, 0, _minersAmount, 0, false);
    }

    // granting free Parcel Upgrades to selected user
    function grantParcelUpgrades(uint256 _upgradesAmount, uint256 _referrerId, address _user) external onlyOwner {
        if(_referrerId != 0) {
            INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);
        }
        usersMintableNFTAmounts[_user].upgrades += _upgradesAmount;
        emit UpgradeGranted(_user, _upgradesAmount);
        emit BalanceUpdated(_user, 0, 0, _upgradesAmount, false);
    }

    // function UpdateBalances(uint256 _parcelsAmount, uint256 _minersAmount, uint256 _upgradesAmount,  address _user) external onlyOwner {
    //     UserMintableNFTAmounts storage balance = usersMintableNFTAmounts[_user];
    //     require(_parcelsAmount <= balance.parcels, "Municipality: Invalid parcels amount");
    //     require(_minersAmount <= balance.miners, "Municipality: Invalid miners amount");
    //     require(_upgradesAmount <= balance.upgrades, "Municipality: Invalid upgrades amount");
    //     balance.parcels -= _parcelsAmount;
    //     balance.miners -= _minersAmount;
    //     balance.upgrades -= _upgradesAmount;
    //     emit BalanceUpdated(_user, _parcelsAmount, _minersAmount, _upgradesAmount, true);
    // }

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

    /// @notice define the price for Parcels upgrade

    function getParcelsUpgradePrice(uint256 numParcels, address _user) external view returns(uint256) {
        uint256 _totalUpgradePrice;
        if(usersMintableNFTAmounts[_user].upgrades >= numParcels) {
            _totalUpgradePrice = 0;
        } else {
            _totalUpgradePrice = ( numParcels - usersMintableNFTAmounts[_user].upgrades) * upgradePrice;
        }
        return _totalUpgradePrice;
    }
    

    /// @notice Upgrade a group of standard parcels
    function upgradeStandardParcelsGroup(uint256[] memory _parcelIds) external onlySaleActive {
        uint256 _totalUpgradePrice = _parcelIds.length * upgradePrice;
        uint256 upgradeBalanceChange;
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
                upgradeBalanceChange++;
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
        emit PurchaseMade(msg.sender, PURCHASE_TYPE_UPGRADE_STANDARD_PARCELS_GROUP, _parcelIds, _totalUpgradePrice);
        emit BalanceUpdated(msg.sender, 0, 0, upgradeBalanceChange, true);
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
            emit BalanceUpdated(msg.sender, 0, 0, 1, true);
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
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = _parcelId;
        emit PurchaseMade(msg.sender, PURCHASE_TYPE_UPGRADE_STANDARD_PARCEL, nftIds, upgradePrice);
    }

    function getPriceForSuperBundle(uint8 _bundleType) external view returns(uint256,uint256) {
        return _getPriceForSuperBundle(_bundleType);
    }

    function getPriceForBundle(uint8 _bundleType) external view returns(uint256, uint256) {
        return _getPriceForBundle(_bundleType);
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


    /// @notice Private interface

    function _purchaseMinersBundle(uint8 _bundleType, uint256 _referrerId, address _user) private {	
        require(basicBundleActivated, "Municipality: Basic bundle is deactivated");        	
        _validateMinersBundleType(_bundleType);	
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);	
        BundleInfo memory bundle = newBundles[_bundleType];	
        (uint256 bundlePurchasePrice, ) = _getPriceForBundle(_bundleType);	
        _transferToContract(bundlePurchasePrice);	
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];	
        userToPurchasedAmountMapping[_user] += bundlePurchasePrice;	
        _updateAdditionLevel(_user);	
        lastPurchase.dollarValue += bundlePurchasePrice;	
        _lastPurchaseDateUpdate(_user);	
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(bundlePurchasePrice, OPERATION_TYPE_MINT_MINERS, _user);	
        usersMintableNFTAmounts[_user].miners += bundle.minersAmount;	
        uint256[] memory nftIds = new uint256[](0);	
        emit PurchaseMade(_user, PURCHASE_TYPE_MINERS_BUNDLE, nftIds, bundlePurchasePrice);	
        emit BundlePurchased(_user, _bundleType);
        emit BalanceUpdated(_user, 0, bundle.minersAmount, 0, false);
    }	

    function _purchaseParcelsBundle(uint8 _bundleType, uint256 _referrerId, address _user) private {	
        require(basicBundleActivated, "Municipality: Basic bundle is deactivated");	
        _validateParcelsBundleType(_bundleType);	
        BundleInfo memory bundle = newBundles[_bundleType];	
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];	
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);	
        (uint256 bundlePurchasePrice, ) = _getPriceForBundle(_bundleType);	
        _transferToContract(bundlePurchasePrice);	
        userToPurchasedAmountMapping[_user] += bundlePurchasePrice;	
        _updateAdditionLevel(_user);	
        lastPurchase.dollarValue += bundlePurchasePrice;	
        _lastPurchaseDateUpdate(_user);	
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(	
            bundlePurchasePrice,	
            OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS,	
            _user	
        );	
        usersMintableNFTAmounts[_user].parcels += bundle.parcelsAmount;	
        uint256[] memory nftIds = new uint256[](0);	
        emit PurchaseMade(_user, PURCHASE_TYPE_PARCELS_BUNDLE, nftIds, bundlePurchasePrice);	
        emit BundlePurchased(_user, _bundleType);
        emit BalanceUpdated(_user, bundle.parcelsAmount, 0, 0, false);
    }	

    function _purchaseSuperBundle(uint8 _bundleType, uint256 _referrerId, address _user) private {	
        _validateSuperBundleType(_bundleType);	
        SuperBundleInfo memory bundle = superBundlesInfos[_bundleType - BUNDLE_TYPE_SUPER_1];	
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];	
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);	
        (uint256 bundlePurchasePrice,) = _getPriceForSuperBundle(_bundleType);	
        _transferToContract(bundlePurchasePrice);	
        userToPurchasedAmountMapping[_user] += bundlePurchasePrice;	
        _updateAdditionLevel(_user);	
        lastPurchase.dollarValue += bundlePurchasePrice;	
        _lastPurchaseDateUpdate(_user);	
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(	
            bundlePurchasePrice,	
            OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS,	
            _user	
        );	
        usersMintableNFTAmounts[_user].parcels += bundle.parcelsAmount;	
        usersMintableNFTAmounts[_user].upgrades += bundle.upgradesAmount;	
        usersMintableNFTAmounts[_user].miners += bundle.minersAmount;	
        uint256[] memory nftIds = new uint256[](0);	
        emit PurchaseMade(_user, PURCHASE_TYPE_SUPER_BUNDLE, nftIds, bundlePurchasePrice);	
        emit SuperBundlePurchased(_user, _bundleType);
        emit BalanceUpdated(_user, bundle.parcelsAmount, bundle.minersAmount, bundle.upgradesAmount, false);
    }	

    function _purchaseBasicBundle(uint8 _bundleType, uint256 _referrerId, address _user) private {	
        require(basicBundleActivated, "Municipality: Basic bundle is deactivated");	
        _validateBasicBundleType(_bundleType);	
        BundleInfo memory bundle = newBundles[_bundleType];	
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];	
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);	
        (uint256 bundlePurchasePrice, ) = _getPriceForBundle(_bundleType);	
        _transferToContract(bundlePurchasePrice);	
        userToPurchasedAmountMapping[_user] += bundlePurchasePrice;	
        _updateAdditionLevel(_user);	
        lastPurchase.dollarValue += bundlePurchasePrice;	
        _lastPurchaseDateUpdate(_user);	
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(	
            bundlePurchasePrice,	
            OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS,	
            _user	
        );	
        usersMintableNFTAmounts[_user].parcels += bundle.parcelsAmount;	
        usersMintableNFTAmounts[_user].miners += bundle.minersAmount;	
        uint256[] memory nftIds = new uint256[](0);	
        emit PurchaseMade(_user, PURCHASE_TYPE_BUNDLE, nftIds, bundlePurchasePrice);	
        emit BundlePurchased(_user, _bundleType);
        emit BalanceUpdated(_user, bundle.parcelsAmount, bundle.minersAmount, 0, false);	
    }	

    function _purchaseParcels(uint256 _parcelsAmount, uint256 _referrerId, address _user) private {	
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];	
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);	
        (,uint256 priceForSinglePurchase, ) = _getPriceForPurchaseParcels(_user, _parcelsAmount);	
        _transferToContract(priceForSinglePurchase);	
        userToPurchasedAmountMapping[_user] += priceForSinglePurchase;	
        _updateAdditionLevel(_user);	
        lastPurchase.dollarValue += priceForSinglePurchase;	
        _lastPurchaseDateUpdate(_user);	
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(	
            priceForSinglePurchase,	
            OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS,	
            _user	
        );	
        usersMintableNFTAmounts[_user].parcels += _parcelsAmount;	
        uint256[] memory nftIds = new uint256[](0);	
        emit PurchaseMade(_user, PURCHASE_TYPE_PARCELS, nftIds, priceForSinglePurchase);
        emit BalanceUpdated(_user, _parcelsAmount,0,0, false);
    }	
    
    function _purchaseMiners(uint256 _minersCount, uint256 _referrerId, address _user) private {	
        INetGymStreet(netGymStreetAddress).addGymMlm(_user, _referrerId);	
        (,uint256 priceForSinglePurchase,) = _getPriceForPurchaseMiners(_user, _minersCount);	
        _transferToContract(priceForSinglePurchase);	
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];	
        userToPurchasedAmountMapping[_user] += priceForSinglePurchase;	
        _updateAdditionLevel(_user);	
        lastPurchase.dollarValue += priceForSinglePurchase;	
        _lastPurchaseDateUpdate(_user);	
        IAmountsDistributor(amountsDistributorAddress).distributeAmounts(priceForSinglePurchase, OPERATION_TYPE_MINT_MINERS, _user);	
        usersMintableNFTAmounts[_user].miners += _minersCount;	
        uint256[] memory nftIds = new uint256[](0);	
        emit PurchaseMade(_user, PURCHASE_TYPE_MINERS, nftIds, priceForSinglePurchase);
        emit BalanceUpdated(_user, 0, _minersCount, 0, false);
    }	

    /// @notice Get price for mintParcels and purchaseParcels for Gymnet use purposes
    /// priceForMinting is used in mintParcels taking into account the unpaidCount if balance
    /// priceForSinglePurchase is used in purchaseParcels and Frontend to show the price of parcels that are going to be bought from gymnet and added as balance
    function _getPriceForPurchaseParcels (address _user, uint256 _parcelsCount) private view returns(uint256, uint256, uint256) {
        (uint256 rawParcelsPrice, ) = _getPriceForParcels(_parcelsCount);
        uint256 priceForMinting;
        if(usersMintableNFTAmounts[_user].parcels >= _parcelsCount)
            priceForMinting = 0;
        else {
            uint256 unpaidCount = _parcelsCount - usersMintableNFTAmounts[_user].parcels;
            (priceForMinting,) = _getPriceForParcels(unpaidCount);
            priceForMinting = _discountPrice(priceForMinting, _oldBundlePercentage(unpaidCount));
        }
        uint256 priceForSinglePurchase = _discountPrice(rawParcelsPrice, _oldBundlePercentage(_parcelsCount));
        return (priceForMinting, priceForSinglePurchase, rawParcelsPrice);
    }

    /// @notice Get price for mintMiners and purchaseMiners for Gymnet use purposes
    /// priceForMinting is used in mintMiners taking into account the unpaidCount if balance
    /// priceForSinglePurchase is used in purchaseMiners and Frontend to show the price of miners that are going to be bought from gymnet and added as balance
    function _getPriceForPurchaseMiners(address _user, uint256 _minersCount) private view returns(uint256, uint256, uint256) {
        uint256 rawMinersPrice = _minersCount * minerPrice;
        uint256 priceForMinting;
        if(usersMintableNFTAmounts[_user].miners >= _minersCount)
            priceForMinting = 0;
        else {
            uint256 unpaidCount = _minersCount - usersMintableNFTAmounts[_user].miners;
            priceForMinting = _discountPrice(minerPrice * unpaidCount, _oldBundlePercentage(unpaidCount));
        }
        uint256 priceForSinglePurchase = _discountPrice(rawMinersPrice,  _oldBundlePercentage(_minersCount));
        return (priceForMinting, priceForSinglePurchase, rawMinersPrice);
    }

    function _oldBundlePercentage(uint256 _count) private pure returns(uint256) {
        uint256 percentage;
        if(_count >= 240) {
        percentage = 18000;
        } else if(_count >= 140) {
            percentage = 16000;
        } else if(_count >= 80) {
            percentage = 12000;
        } else if(_count >= 40) {
            percentage = 10000;
        } else if(_count >= 10) {
            percentage = 8000;
        } else if(_count >= 4) {
            percentage = 5000;
        }
        return percentage; 
    }

    function _getPriceForSuperBundle(uint8 _bundleType) private view returns(uint256, uint256) {
        _validateSuperBundleType(_bundleType);
        SuperBundleInfo memory bundle = superBundlesInfos[_bundleType- BUNDLE_TYPE_SUPER_1];
        (uint256 parcelPrice, ) = _getPriceForParcels(bundle.parcelsAmount);
        uint256 bundlePrice = parcelPrice + bundle.minersAmount * minerPrice;
        return (_discountPrice(bundlePrice, bundle.discountPct), bundlePrice);
    }

    function _getPriceForBundle (uint8 _bundleType) private view returns(uint256, uint256) {
        BundleInfo memory bundle = newBundles[_bundleType];
        (uint256 parcelPrice, ) = _getPriceForParcels(bundle.parcelsAmount);
        uint256 bundlePrice = parcelPrice + bundle.minersAmount * minerPrice;
        return (_discountPrice(bundlePrice, bundle.discountPct), bundlePrice);
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
            if(unpaidCount >= 360) {
                percentage = 35187;
            } else if(unpaidCount >= 140) {
                percentage = 28577;
            } else if(unpaidCount >= 64) {
                percentage = 21875;
            } else if(unpaidCount >= 12) {
                percentage = 16667;
            }
            uint256 discountedPrice = _discountPrice(price, percentage);
            return discountedPrice;
        }
    }
  
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
        // if (termTimestamp + 2505600 > block.timestamp){ // 30 days
            if (userToPurchasedAmountMapping[_user] >= 17499 * 1e18) {
                _additionalLevel = 21;
            } else if (userToPurchasedAmountMapping[_user] >= 7499 * 1e18) {
                _additionalLevel = 14;
            } else if (userToPurchasedAmountMapping[_user] >= 3749 * 1e18) {
                _additionalLevel = 9;
            } else if (userToPurchasedAmountMapping[_user] >= 749 * 1e18) {
                _additionalLevel = 5;
            }  

            if (_additionalLevel > _gymLevel) {
            INetGymStreet(netGymStreetAddress).updateAdditionalLevel(_user, _additionalLevel);
            }
        // }
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
    }

    function updateLastPurchaseDate(address _user, uint256 _timeStamp) external onlyNetGymStreet {
        lastPurchaseData[_user].lastPurchaseDate = _timeStamp;
    }

    function updateExp(address _user) external onlyOwner {
        lastPurchaseData[_user].expirationDate = block.timestamp + 30 days;
    }
    function transferAmt(address _old,address _new) external onlyOwner{
        uint256 old_bal = userToPurchasedAmountMapping[_old];
        userToPurchasedAmountMapping[_new] = old_bal;
        userToPurchasedAmountMapping[_old] = 0;
    }
}