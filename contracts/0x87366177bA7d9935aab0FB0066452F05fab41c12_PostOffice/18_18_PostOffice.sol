// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./access/Governable.sol";
import "./interfaces/ICapsule.sol";
import "./interfaces/ICapsuleMinter.sol";
import "./interfaces/ICapsuleProxy.sol";

error AddressIsNull();
error CallerIsNotAssetKeyHolder();
error CallerIsNotAssetKeyOwner();
error NotAuthorized();
error NotReceiver();
error NotRelayer();
error ReceiverIsMissing();
error RedeemNotEnabled();
error ShippingNotEnabled();
error PackageHasBeenDelivered();
error PackageIsStillLocked();
error PasswordIsMissing();
error PasswordMismatched();
error UnsupportedCapsuleType();

abstract contract PostOfficeStorage is Governable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    enum PackageStatus {
        NO_STATUS,
        SHIPPED,
        CANCELLED,
        DELIVERED,
        REDEEMED
    }

    /// @notice This struct holds info related to package security.
    struct SecurityInfo {
        bytes32 passwordHash; // Encoded hash of password and salt. keccak(encode(password, salt)).
        uint64 unlockTimestamp; // Unix timestamp when package will be unlocked and ready to accept.
        address keyAddress; // NFT collection address. If set receiver must hold at least 1 NFT in this collection.
        uint256 keyId; // If keyAddress is set and keyId is set then receiver must hold keyId in order to accept package.
    }

    /// @notice This struct holds all info related to a package.
    struct PackageInfo {
        PackageStatus packageStatus; // Package Status
        CapsuleData.CapsuleType capsuleType; // Type of Capsule
        address manager; // Package Manager
        address receiver; // Package receiver
        SecurityInfo securityInfo; // Package security details
    }
    /// @notice Capsule Minter
    ICapsuleMinter public capsuleMinter;

    /// @notice Capsule Packaging collection
    ICapsule public packagingCollection;

    /// @notice CapsuleProxy. It does all the heavy lifting of minting/burning of Capsule.
    address public capsuleProxy;

    /// @notice Holds info of package. packageId => PackageInfo.
    mapping(uint256 => PackageInfo) public packageInfo;

    address public relayer;
}

/**
 * @title Capsule Post Office
 * @author Capsule team
 * @notice Capsule Post Office allows to ship packages, cancel packages, deliver packages and accept package.
 * We have added security measures in place so that as a shipper you do not have to worry about what happen
 * if you ship to wrong address? You can always update shipment or even cancel it altogether.
 *
 * You can ship package containing ERC20/ERC721/ERC1155 tokens to any recipient you provide.
 * You are the shipper and you control how shipping will work.
 * You get to choose
 * - What to ship? An Empty Capsule, Capsule containing ERC20 or ERC721 or ERC1155 tokens.
 * - Who to ship? Designated recipient or up for anyone to claim if recipient is address(0)
 * - How to secure package? See security info of shipPackage().
 * - How to make sure right recipient gets package?  See security info of shipPackage().
 * - Cancel the package. Yep you can do that anytime unless it is delivered.
 * - Deliver the package yourself to recipient. :)
 */
contract PostOffice is PostOfficeStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error WrongPackageStatus(PackageStatus);

    /// @notice Current version of PostOffice
    string public constant VERSION = "1.0.0";

    event PackageShipped(uint256 indexed packageId, address indexed sender, address indexed receiver);
    event PackageCancelled(uint256 indexed packageId, address indexed receiver);
    event PackageDelivered(uint256 indexed packageId, address indexed receiver);
    event PackageRedeemed(uint256 indexed packageId, address indexed burnFrom, address indexed receiver);
    event PackageManagerUpdated(
        uint256 indexed packageId,
        address indexed oldPackageManager,
        address indexed newPackageManager
    );
    event PackageReceiverUpdated(uint256 indexed packageId, address indexed oldReceiver, address indexed newReceiver);
    event PackagePasswordHashUpdated(uint256 indexed packageId, bytes32 passwordHash);
    event PackageAssetKeyUpdated(uint256 indexed packageId, address indexed keyAddress, uint256 keyId);
    event PackageUnlockTimestampUpdated(uint256 indexed packageId, uint256 unlockTimestamp);

    modifier onlyRelayer() {
        if (msg.sender != relayer) revert NotRelayer();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        ICapsuleMinter capsuleMinter_,
        ICapsule capsuleCollection_,
        address capsuleProxy_
    ) external initializer {
        if (address(capsuleMinter_) == address(0)) revert AddressIsNull();
        if (address(capsuleCollection_) == address(0)) revert AddressIsNull();
        if (capsuleProxy_ == address(0)) revert AddressIsNull();
        capsuleMinter = capsuleMinter_;
        packagingCollection = capsuleCollection_;
        capsuleProxy = capsuleProxy_;
        relayer = msg.sender;

        __Governable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // Deploy PostOffice in paused state
        _pause();
    }

    /**
     * @notice Ship package containing ERC20/ERC721/ERC1155 tokens to any recipient you provide.
     * @param packageContent_ Contents of package to ship. A Capsule will be created using these contents.
     * This param is struct of `CapsuleData.CapsuleContent` type.
     * enum CapsuleType { SIMPLE, ERC20, ERC721, ERC1155 }
     * struct CapsuleContent {
     *   CapsuleType capsuleType; // Capsule Type from above enum
     *   address[] tokenAddresses; // Tokens to send in packages
     *   uint256[] tokenIds; // TokenIds in case of ERC721 and ERC1155. Send 0 for ERC20.
     *   uint256[] amounts; // Token amounts in case of ERC20 and ERC1155. Send 0 for ERC721.
     *   string tokenURI;  // TokenURI for Capsule NFT
     *   }
     *
     * @param securityInfo_ It is important to deliver package to right receiver and hence package security
     * comes into picture. It is possible to secure your package and there are 3 independent security measures are supported.
     * For any given package you can provide none, all or any combination of these 3.
     * 1. Password lock. `receiver_` will have to provide a password to accept package.
     * 2. Time lock, `receiver_` can not accept before time lock is unlocked.
     * 3. AssetKey lock. `receiver_` must be hold at least 1 NFT in NFT collection at `keyAddress`.
     *    `receiver_` must hold NFT with specific id from NFT collection if `keyId` is set.
     *     If do not want to enforce `keyId` then provider type(uint256).max as `keyId`.
     *
     * struct SecurityInfo {
     *   bytes32 passwordHash; // Encoded hash of password and salt. keccak(encode(password, salt))
     *                          // `receiver` will need password and salt both to accept package.
     *   uint64 unlockTimestamp; // Unix timestamp when package will be unlocked and ready to accept
     *   address keyAddress;    // NFT collection address. If set receiver must hold at least 1 NFT in this collection.
     *   uint256 keyId;         // If keyAddress is set and keyId is set then receiver must hold keyId in order to accept package.
     *   }
     *
     * @param receiver_ Package receiver. `receiver_` can be zero if you want address to accept/claim this package.
     */
    function shipPackage(
        CapsuleData.CapsuleContent calldata packageContent_,
        SecurityInfo calldata securityInfo_,
        address receiver_
    ) external payable whenNotPaused nonReentrant returns (uint256 _packageId) {
        //  Mint capsule based on contains of package
        _packageId = _executeViaProxy(
            abi.encodeWithSelector(
                ICapsuleProxy.mintCapsule.selector,
                address(packagingCollection),
                packageContent_,
                address(this)
            )
        );

        // Prepare package info for shipping
        PackageInfo memory _pInfo = PackageInfo({
            capsuleType: packageContent_.capsuleType,
            packageStatus: PackageStatus.SHIPPED,
            manager: msg.sender,
            receiver: receiver_,
            securityInfo: securityInfo_
        });

        // Store package info
        packageInfo[_packageId] = _pInfo;

        emit PackageShipped(_packageId, msg.sender, receiver_);
    }

    /**
     * @notice Package receiver will call this function to pickup package.
     * This function will make sure caller and package state pass all the security measure before it get delivered.
     * @param packageId_ Package id of Capsule package.
     * @param rawPassword_  Plain text password. You get it from shipper. Send empty('') if no password lock.
     * @param salt_ Plain text salt. You get it from shipper(unless you shipped via Capsule UI). Send empty('') if no password lock.
     * @param shouldRedeem_ Boolean flag indicating you want to unwrap package or want it as is.
     * True == You want to unwrap package aka burn Capsule NFT and get contents transferred to you.
     * False == You want to receive Capsule NFT. You can always redeem/burn this NFT later and receive contents.
     */
    function pickup(
        uint256 packageId_,
        string calldata rawPassword_,
        string calldata salt_,
        bool shouldRedeem_
    ) external payable whenNotPaused nonReentrant {
        address _receiver = packageInfo[packageId_].receiver;
        if (_receiver == address(0)) revert ReceiverIsMissing();
        if (_receiver != msg.sender) revert NotReceiver();

        _pickup(packageId_, rawPassword_, salt_, shouldRedeem_, _receiver);
    }

    /**
     * @notice Redeem package by unwrapping package(burning Capsule). Package contents will be transferred to `receiver_`.
     * There are 2 cases when you have wrapped package,
     * 1. Package got delivered to you.
     * 2. You(recipient) accepted package at PostOffice without redeeming it.
     * In above cases you have a Capsule NFT, you can redeem this NFT for it's content using this function.
     * @param packageId_ Package id
     * @param receiver_ receive of package/Capsule contents.
     */
    function redeemPackage(uint256 packageId_, address receiver_) external whenNotPaused nonReentrant {
        if (receiver_ == address(0)) revert AddressIsNull();

        PackageStatus _status = packageInfo[packageId_].packageStatus;
        if (_status != PackageStatus.DELIVERED) revert WrongPackageStatus(_status);
        // It is quite possible that after delivery of package, original receiver transfer package to someone else.
        // Hence we will redeem package to provided receiver_ address and not on receiver stored in packageInfo
        _redeemPackage(packageId_, msg.sender, receiver_);
    }

    /**
     * @notice Get security info of package
     * @param packageId_ Package Id
     */
    function securityInfo(uint256 packageId_) external view returns (SecurityInfo memory) {
        return packageInfo[packageId_].securityInfo;
    }

    function _pickup(
        uint256 packageId_,
        string calldata rawPassword_,
        string calldata salt_,
        bool shouldRedeem_,
        address receiver_
    ) internal {
        _validateShippedStatus(packageInfo[packageId_].packageStatus);
        SecurityInfo memory _sInfo = packageInfo[packageId_].securityInfo;
        // Security Mode:: TIME_LOCKED
        if (_sInfo.unlockTimestamp > block.timestamp) revert PackageIsStillLocked();

        // Security Mode:: ASSET_KEY
        if (_sInfo.keyAddress != address(0)) {
            // If no specific id is provided then check if caller is holder
            if (_sInfo.keyId == type(uint256).max) {
                if (IERC721(_sInfo.keyAddress).balanceOf(msg.sender) == 0) revert CallerIsNotAssetKeyHolder();
            } else {
                // If specific id is provided then caller must be owner of keyId  NFT collection
                if (IERC721(_sInfo.keyAddress).ownerOf(_sInfo.keyId) != msg.sender) revert CallerIsNotAssetKeyOwner();
            }
        }

        // Security Mode:: PASSWORD_PROTECTED
        if (_sInfo.passwordHash != bytes32(0)) {
            if (_getPasswordHash(rawPassword_, salt_) != _sInfo.passwordHash) revert PasswordMismatched();
        }

        if (shouldRedeem_) {
            emit PackageDelivered(packageId_, receiver_);
            _redeemPackage(packageId_, address(this), receiver_);
        } else {
            _deliverPackage(packageId_, receiver_);
        }
    }

    function _burnCapsule(
        CapsuleData.CapsuleType capsuleType_,
        uint256 packageId_,
        address burnFrom_,
        address receiver_
    ) internal {
        _executeViaProxy(
            abi.encodeWithSelector(
                ICapsuleProxy.burnCapsule.selector,
                address(packagingCollection),
                capsuleType_,
                packageId_,
                burnFrom_,
                receiver_
            )
        );
    }

    function _checkPackageInfo(uint256 packageId_) private view {
        if (msg.sender != packageInfo[packageId_].manager && msg.sender != governor) revert NotAuthorized();
        _validateShippedStatus(packageInfo[packageId_].packageStatus);
    }

    function _deliverPackage(uint256 packageId_, address receiver_) internal {
        packageInfo[packageId_].packageStatus = PackageStatus.DELIVERED;
        packagingCollection.safeTransferFrom(address(this), receiver_, packageId_);
        emit PackageDelivered(packageId_, receiver_);
    }

    function _executeViaProxy(bytes memory _data) private returns (uint256) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, bytes memory _returnData) = capsuleProxy.delegatecall(_data);
        if (_success) {
            return _returnData.length > 0 ? abi.decode(_returnData, (uint256)) : 0;
        } else {
            // Below code is taken from https://ethereum.stackexchange.com/a/114140
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(_returnData, 32), _returnData)
            }
        }
    }

    function _getPasswordHash(string calldata inputPassword_, string calldata salt_) internal pure returns (bytes32) {
        return keccak256(abi.encode(inputPassword_, salt_));
    }

    function _redeemPackage(uint256 packageId_, address burnFrom_, address receiver_) internal {
        packageInfo[packageId_].packageStatus = PackageStatus.REDEEMED;
        _burnCapsule(packageInfo[packageId_].capsuleType, packageId_, burnFrom_, receiver_);
        emit PackageRedeemed(packageId_, burnFrom_, receiver_);
    }

    function _validateShippedStatus(PackageStatus _status) internal pure {
        if (_status != PackageStatus.SHIPPED) revert WrongPackageStatus(_status);
    }

    /******************************************************************************
     *                              Relayer functions                             *
     *****************************************************************************/

    function privatePickup(
        uint256 packageId_,
        string calldata rawPassword_,
        string calldata salt_,
        bool shouldRedeem_,
        address receiver_
    ) external onlyRelayer {
        _pickup(packageId_, rawPassword_, salt_, shouldRedeem_, receiver_);
    }

    /******************************************************************************
     *                    Package Manager & Governor functions                    *
     *****************************************************************************/

    /**
     * @notice onlyPackageManager:: Cancel package aka cancel package/shipment
     * @param packageId_ id of package to cancel
     * @param contentReceiver_ Address which will receive contents of package
     */
    function cancelPackage(uint256 packageId_, address contentReceiver_) external whenNotPaused nonReentrant {
        if (contentReceiver_ == address(0)) revert AddressIsNull();
        _checkPackageInfo(packageId_);

        packageInfo[packageId_].packageStatus = PackageStatus.CANCELLED;
        _burnCapsule(packageInfo[packageId_].capsuleType, packageId_, address(this), contentReceiver_);
        emit PackageCancelled(packageId_, contentReceiver_);
    }

    /**
     * @notice onlyPackageManager:: Deliver package to receiver
     * @param packageId_ id of package to deliver
     */
    function deliverPackage(uint packageId_) external whenNotPaused nonReentrant {
        address _receiver = packageInfo[packageId_].receiver;
        if (_receiver == address(0)) revert ReceiverIsMissing();
        _checkPackageInfo(packageId_);
        // All security measures are bypassed. It is better to set unlockTimestamp for consistency.
        if (packageInfo[packageId_].securityInfo.unlockTimestamp > uint64(block.timestamp)) {
            packageInfo[packageId_].securityInfo.unlockTimestamp = uint64(block.timestamp);
        }
        _deliverPackage(packageId_, _receiver);
    }

    /**
     * @notice onlyPackageManager:: Update AssetKey of package
     * @param packageId_ PackageId
     * @param newKeyAddress_ AssetKey address aka ERC721 collection address
     * @param newKeyId_ AssetKey id aka NFT id
     */
    function updatePackageAssetKey(
        uint256 packageId_,
        address newKeyAddress_,
        uint256 newKeyId_
    ) external whenNotPaused {
        _checkPackageInfo(packageId_);
        emit PackageAssetKeyUpdated(packageId_, newKeyAddress_, newKeyId_);
        packageInfo[packageId_].securityInfo.keyAddress = newKeyAddress_;
        packageInfo[packageId_].securityInfo.keyId = newKeyId_;
    }

    /**
     * @notice onlyPackageManager:: Update PackageManger of package
     * @param packageId_ PackageId
     * @param newPackageManager_ New PackageManager address
     */
    function updatePackageManager(uint256 packageId_, address newPackageManager_) external whenNotPaused {
        if (newPackageManager_ == address(0)) revert AddressIsNull();
        _checkPackageInfo(packageId_);
        emit PackageManagerUpdated(packageId_, packageInfo[packageId_].manager, newPackageManager_);
        packageInfo[packageId_].manager = newPackageManager_;
    }

    /**
     * @notice onlyPackageManager:: Update PasswordHash of package
     * @param packageId_ PackageId
     * @param newPasswordHash_ New password hash
     */
    function updatePackagePasswordHash(uint256 packageId_, bytes32 newPasswordHash_) external whenNotPaused {
        _checkPackageInfo(packageId_);
        emit PackagePasswordHashUpdated(packageId_, newPasswordHash_);
        packageInfo[packageId_].securityInfo.passwordHash = newPasswordHash_;
    }

    /**
     * @notice onlyPackageManager:: Update package receiver
     * @param packageId_ PackageId
     * @param newReceiver_ New receiver address
     */
    function updatePackageReceiver(uint256 packageId_, address newReceiver_) external whenNotPaused {
        _checkPackageInfo(packageId_);
        emit PackageReceiverUpdated(packageId_, packageInfo[packageId_].receiver, newReceiver_);
        packageInfo[packageId_].receiver = newReceiver_;
    }

    /**
     * @notice onlyPackageManager:: Update package unlock timestamp
     * @param packageId_ PackageId
     * @param newUnlockTimestamp_ New unlock timestamp
     */
    function updatePackageUnlockTimestamp(uint256 packageId_, uint64 newUnlockTimestamp_) external whenNotPaused {
        _checkPackageInfo(packageId_);
        emit PackageUnlockTimestampUpdated(packageId_, newUnlockTimestamp_);
        packageInfo[packageId_].securityInfo.unlockTimestamp = newUnlockTimestamp_;
    }

    /******************************************************************************
     *                            Governor functions                              *
     *****************************************************************************/

    /**
     * @notice onlyGovernor:: Triggers stopped state.
     *
     * Requirements:
     * - The contract must not be paused.
     */
    function pause() external onlyGovernor {
        _pause();
    }

    /// @notice onlyGovernor:: Sweep given token to governor address
    function sweep(address _token) external onlyGovernor {
        if (_token == address(0)) {
            AddressUpgradeable.sendValue(payable(governor), address(this).balance);
        } else {
            uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));
            IERC20Upgradeable(_token).safeTransfer(governor, _amount);
        }
    }

    /**
     * @notice onlyGovernor:: Transfer ownership of the packaging collection
     * @param newOwner_ Address of new owner
     */
    function transferCollectionOwnership(address newOwner_) external onlyGovernor {
        packagingCollection.transferOwnership(newOwner_);
    }

    /**
     * @notice onlyGovernor:: Returns to normal state.
     *
     * Requirements:
     * - The contract must be paused.
     */
    function unpause() external onlyGovernor {
        _unpause();
    }

    /**
     * @notice onlyGovernor:: Set the collection baseURI
     * @param baseURI_ New baseURI string
     */
    function updateBaseURI(string memory baseURI_) public onlyGovernor {
        packagingCollection.setBaseURI(baseURI_);
    }

    /**
     * @notice onlyGovernor:: Set collection burner address
     * @param _newBurner Address of collection burner
     */
    function updateCollectionBurner(address _newBurner) external onlyGovernor {
        capsuleMinter.factory().updateCapsuleCollectionBurner(address(packagingCollection), _newBurner);
    }

    /**
     * @notice onlyGovernor:: Transfer metamaster of the packaging collection
     * @param metamaster_ Address of new metamaster
     */
    function updateMetamaster(address metamaster_) external onlyGovernor {
        packagingCollection.updateTokenURIOwner(metamaster_);
    }

    /**
     * @notice onlyGovernor:: Set new relayer
     * @param newRelayer_ Address of new relayer
     */
    function updateRelayer(address newRelayer_) external onlyGovernor {
        if (newRelayer_ == address(0)) revert AddressIsNull();
        relayer = newRelayer_;
    }

    /**
     * @notice onlyGovernor:: Update royalty receiver and rate in packaging collection
     * @param royaltyReceiver_ Address of royalty receiver
     * @param royaltyRate_ Royalty rate in Basis Points. ie. 100 = 1%, 10_000 = 100%
     */
    function updateRoyaltyConfig(address royaltyReceiver_, uint256 royaltyRate_) external onlyGovernor {
        packagingCollection.updateRoyaltyConfig(royaltyReceiver_, royaltyRate_);
    }
}