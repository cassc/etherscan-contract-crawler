// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/IRoyaltySplitter.sol";
import "./interfaces/IMinterceptor.sol";
import "./interfaces/ICollection.sol";
import "./MinterceptorStorage.sol";
import "../ManageableUpgradeable.sol";
import "../QuantumBlackListable.sol";

error NotAuthorized();
error InvalidTargetContract(address collectionContract);
error InvalidTreasuryAddress();

contract Minterceptor is
    IMinterceptor,
    OwnableUpgradeable,
    ManageableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using MinterceptorStorage for MinterceptorStorage.Layout;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    event MintForwarded(
        uint256 voucherId,
        address collectionContract,
        uint256 indexed itemId,
        address to
    );

    event MintEditionsForwarded(
        uint256 voucherId,
        address collectionContract,
        uint256 indexed itemId,
        uint256 indexed tokenId,
        uint256 quantity,
        address to
    );

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function initialize(
        address admin,
        address blacklist,
        address payable treasury
    ) public initializer {
        __Minterceptor_init(admin, blacklist, treasury);
    }

    function __Minterceptor_init(
        address admin,
        address blacklist,
        address payable treasury
    ) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Minterceptor_init_unchained(admin, blacklist, treasury);
    }

    function __Minterceptor_init_unchained(
        address admin,
        address blacklist,
        address payable treasury
    ) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);
        setBlacklist(blacklist);
        MinterceptorStorage.Layout storage m = MinterceptorStorage.layout();
        m.treasury = treasury;
        m.defaultPlatformFee = 500; //bps
    }

    /// >>>>>>>>>>>>>>>>>>>>>  PERMISSIONS  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice set address of the minter
    /// @param owner The address of the new owner
    function setOwner(address owner) public onlyOwner {
        transferOwnership(owner);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function setManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function unsetManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    /// @notice update the blacklist contract
    /// @param blacklist The address of the blacklist contract
    function setBlacklist(address blacklist)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        MinterceptorStorage.Layout storage m = MinterceptorStorage.layout();
        m.blackListAddress = blacklist;
    }

    /// @notice update the default platform fees
    /// @param fee BPS value of the studio platform fee
    function setDefaultPlatformFee(uint256 fee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        MinterceptorStorage.Layout storage m = MinterceptorStorage.layout();
        m.defaultPlatformFee = fee;
    }

    /// @notice update the platform fee for a particular collection
    /// @param collection address of the collection for the override fee
    /// @param fee BPS value of the studio platform fee
    function setOverridePlatformFee(address collection, uint256 fee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        MinterceptorStorage.layout().overridePlatformFee[collection] = fee;
    }

    /// @notice Set the treasury address
    /// @param treasury Address of the treasury
    function setTreasury(address payable treasury)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        if (treasury == address(0)) revert InvalidTreasuryAddress();
        MinterceptorStorage.Layout storage m = MinterceptorStorage.layout();
        m.treasury = treasury;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  CONTRACT MANAGEMENT  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Pause contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// >>>>>>>>>>>>>>>>>>>>>  BLACKLIST OPS  <<<<<<<<<<<<<<<<<<<<<< ///
    modifier isNotBlackListed(address user) {
        if (
            QuantumBlackListable.isBlackListed(
                user,
                MinterceptorStorage.layout().blackListAddress
            )
        ) {
            revert QuantumBlackListable.BlackListedAddress(user);
        }
        _;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  GETTER FUNCTIONS  <<<<<<<<<<<<<<<<<<<<<< ///

    function platformFee(address collection) public view returns (uint256) {
        return
            overridePlatformFee(collection) > 0
                ? overridePlatformFee(collection)
                : defaultPlatformFee();
    }

    function defaultPlatformFee() public view returns (uint256) {
        return MinterceptorStorage.layout().defaultPlatformFee;
    }

    function overridePlatformFee(address collection)
        public
        view
        returns (uint256)
    {
        return MinterceptorStorage.layout().overridePlatformFee[collection];
    }

    /// >>>>>>>>>>>>>>>>>>>>>  CORE FUNCTIONALITY  <<<<<<<<<<<<<<<<<<<<<< ///

    // Pay splits if royalty splitting supported
    function handleRoyalties(address collection) private {
        MinterceptorStorage.Layout storage m = MinterceptorStorage.layout();

        uint256 platformValue = (msg.value * platformFee(collection)) / 10000;
        m.treasury.sendValue(platformValue);

        // Pay splits if royalty splitting supported
        try
            IERC165Upgradeable(collection).supportsInterface(
                type(IRoyaltySplitter).interfaceId
            )
        returns (bool royaltySplitSupported) {
            if (royaltySplitSupported) {
                // Get receiver addresses and splits from the collection contract
                Recipient[] memory recipients = IRoyaltySplitter(collection)
                    .getRecipients();
                // Pay artist royalty splits
                for (uint256 i = 0; i < recipients.length; i++) {
                    payable(recipients[i].recipient).sendValue(
                        ((msg.value - platformValue) * recipients[i].bps) /
                            10000
                    );
                }
            } else {
                // Get receiver address from the collection contract
                (address receiver, uint256 royaltyAmount) = IERC2981(collection)
                    .royaltyInfo(0, 1 ether);
                // Pay single artist
                payable(receiver).sendValue(msg.value - platformValue);
            }
        } catch {}
    }

    function mintByUri(
        uint256 voucherId,
        address collectionContract,
        uint256 itemId,
        address to,
        string calldata uri,
        bytes calldata data
    ) public payable onlyRole(MANAGER_ROLE) whenNotPaused isNotBlackListed(to) {
        if (!collectionContract.isContract())
            revert InvalidTargetContract(collectionContract);

        try
            IERC165Upgradeable(collectionContract).supportsInterface(
                type(IERC2981).interfaceId
            )
        returns (bool supported) {
            if (supported) {
                IMintByUri collection = IMintByUri(collectionContract);
                collection.mint(to, uri, data);

                emit MintForwarded(voucherId, collectionContract, itemId, to);

                handleRoyalties(collectionContract);
            } else {
                revert InvalidTargetContract(collectionContract);
            }
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            // Contracts doesn't support IStudioRoyalties
            revert InvalidTargetContract(collectionContract);
        }
    }

    function _setItemTokenId(address collectionContract, uint256 itemId)
        internal
        returns (uint256)
    {
        MinterceptorStorage.Layout storage m = MinterceptorStorage.layout();

        if (m.itemIdToTokenId[collectionContract][itemId] == 0) {
            m.currentTokenId[collectionContract]++;
            m.itemIdToTokenId[collectionContract][itemId] = m.currentTokenId[
                collectionContract
            ];
        }
        return m.itemIdToTokenId[collectionContract][itemId];
    }

    function mintEditions(
        MintEditionsParams calldata mintParams,
        bytes calldata data
    )
        public
        payable
        onlyRole(MANAGER_ROLE)
        whenNotPaused
        isNotBlackListed(mintParams.to)
    {
        if (!mintParams.collection.isContract())
            revert InvalidTargetContract(mintParams.collection);

        try
            IERC165Upgradeable(mintParams.collection).supportsInterface(
                type(IERC2981).interfaceId
            )
        returns (bool supported) {
            if (supported) {
                uint256 tokenId = _setItemTokenId(
                    mintParams.collection,
                    mintParams.itemId
                );

                IMintEditions collection = IMintEditions(mintParams.collection);
                collection.mint(
                    mintParams.to,
                    tokenId,
                    mintParams.quantity,
                    data
                );

                emit MintEditionsForwarded(
                    mintParams.voucherId,
                    mintParams.collection,
                    mintParams.itemId,
                    tokenId,
                    mintParams.quantity,
                    mintParams.to
                );

                handleRoyalties(mintParams.collection);
            } else {
                revert InvalidTargetContract(mintParams.collection);
            }
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            // Contracts doesn't support IStudioRoyalties
            revert InvalidTargetContract(mintParams.collection);
        }
    }

    function mintEditions(
        MintEditionsParams calldata mintParams,
        string calldata _tokenUri,
        bytes calldata data
    )
        public
        payable
        onlyRole(MANAGER_ROLE)
        whenNotPaused
        isNotBlackListed(mintParams.to)
    {
        if (!mintParams.collection.isContract())
            revert InvalidTargetContract(mintParams.collection);

        try
            IERC165Upgradeable(mintParams.collection).supportsInterface(
                type(IERC2981).interfaceId
            )
        returns (bool supported) {
            if (supported) {
                uint256 tokenId = _setItemTokenId(
                    mintParams.collection,
                    mintParams.itemId
                );

                IMintEditions collection = IMintEditions(mintParams.collection);
                collection.mint(
                    mintParams.to,
                    tokenId,
                    _tokenUri,
                    mintParams.quantity,
                    data
                );

                emit MintEditionsForwarded(
                    mintParams.voucherId,
                    mintParams.collection,
                    mintParams.itemId,
                    tokenId,
                    mintParams.quantity,
                    mintParams.to
                );

                handleRoyalties(mintParams.collection);
            } else {
                revert InvalidTargetContract(mintParams.collection);
            }
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            // Contracts doesn't support IStudioRoyalties
            revert InvalidTargetContract(mintParams.collection);
        }
    }
}