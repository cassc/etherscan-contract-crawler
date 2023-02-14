// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./GasRestrictor.sol";
import "./Gamification.sol";
import "./WalletRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract SubscriptionModule is Initializable, OwnableUpgradeable {
    // uint256 public chainId;
    uint256 public defaultCredits;
    uint256 public renewalPeriod;
    GasRestrictor public gasRestrictor;
    Gamification public gamification;
    WalletRegistry public walletRegistry;
    // --------------------- DAPPS STORAGE -----------------------

    struct Dapp {
        string appName;
        bytes32 appId;
        address appAdmin; //primary
        string appUrl;
        string appIcon;
        string appSmallDescription;
        string appLargeDescription;
        string appCoverImage;
        string[] appScreenshots; // upto 5
        string[] appCategory; // upto 7
        string[] appTags; // upto 7
        string[] appSocial;
        bool isVerifiedDapp; // true or false
        uint256 credits;
        uint256 renewalTimestamp;    }

    struct Notification {
        bytes32 appID;
        address walletAddressTo; // primary
        string message;
        string buttonName;
        string cta;
        uint256 timestamp;
        bool isEncrypted;
    }

    struct List {
        uint256 listId;
        string listname;
    }

    mapping(bytes32 => mapping(uint256 => bool)) public isValidList;
    mapping(bytes32 => mapping(uint256 => uint256)) public listUserCount;
    mapping(bytes32 => uint256) public listsOfDappCount;
    mapping(bytes32 => mapping(uint256=> List)) public listsOfDapp;

    mapping(bytes32 => Dapp) public dapps;

    // all dapps count
    uint256 public dappsCount;
    uint256 public verifiedDappsCount;

    mapping(bytes32=>mapping(address=>bool)) hasPreviouslysubscribed;

    mapping(address => Notification[]) public notificationsOf;

    // dappId => count
    mapping(bytes32 => uint256) public notificationsCount;
    // dappId => listIndex => bool

    // dappId => count
    mapping(bytes32 => uint256) public subscriberCount;

    // user=>subscribeAppsCount
    mapping(address => uint256) public subscriberCountUser;
    mapping(address => uint256) public appCountUser;

    // account => dappId => role // 0 means no role, 1 meaning only notif, 2 meaning only add admin, 3 meaning both
    mapping(address => mapping(bytes32 => uint8)) public accountRole;

    // dappId =>list=> address => bool(true/false)
    mapping(bytes32 => mapping(uint256 => mapping(address => bool)))
        public isSubscribed;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant SUBSC_PERMIT_TYPEHASH =
        keccak256(
            "SubscPermit(address user,bytes32 appID,bool subscriptionStatus,uint256 nonce,uint256 deadline)"
        );
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public DOMAIN_SEPARATOR = keccak256(abi.encode(
    //     EIP712_DOMAIN_TYPEHASH,
    //     keccak256(bytes("Dapps")),
    //     keccak256(bytes("1")),
    //     chainId,
    //     address(this)
    // ));

    mapping(address => uint256) public nonce;

    uint256 public noOfSubscribers;
    uint256 public noOfNotifications;

    // dappId => dapp contract address => status
    mapping(bytes32 => mapping(address => bool)) public registeredDappContracts;
    
    // to keep a count of contracts that are using our sdk
    uint256 regDappContractsCount;

    modifier onlySuperAdmin() {
        _onlySuperAdmin();
        _;
    }
    modifier isValidSenderOrRegDappContract(address from, bytes32 dappId) {
        _isValidSenderOrRegDappContract(from, dappId);
        _;
    }

    modifier superAdminOrDappAdmin(bytes32 appID) {
        _superAdminOrDappAdmin(appID);
        _;
    }

    modifier superAdminOrDappAdminOrAddedAdmin(bytes32 appID) {
        _superAdminOrDappAdminOrAddedAdmin(appID);
        _;
    }

    modifier superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(bytes32 appID) {
        _superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(appID);
        _;
    }

    modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    // modifier isRegisteredDappContract(
    //     bytes32 _dappId
    // ) {
    //     require(registeredDappContracts[_dappId][_msgSender()], "UNREGISTERED");
    //     _;
    // }

    event NewAppRegistered(
        bytes32 appID,
        address appAdmin,
        string appName,
        uint256 dappCount
    );

    event AppUpdated(bytes32 appID);

    event AppRemoved(bytes32 appID, uint256 dappCount);

    event AppAdmin(bytes32 appID, address appAdmin, address admin, uint8 role);

    event AppSubscribed(
        bytes32 appID,
        address subscriber,
        uint256 count,
        uint256 totalCount
    );

    event ListCreated(bytes32 appID, uint256 listId);

    event AppUnSubscribed(
        bytes32 appID,
        address subscriber,
        uint256 count,
        uint256 totalCount
    );

    event UserMovedFromList(
        bytes32 appID,
        address user,
        uint256 listIdFrom,
        uint256 listIdTo
    );
    event UserAddedToList(
        bytes32 appID,
        address user,
        uint256 listIdTo
    );
    event UserRemovedFromList(
        bytes32 appID,
        address user,
        uint256 listIdTo
    );

    event NewNotification(
        bytes32 appId,
        address walletAddress,
        string message,
        string buttonName,
        string cta,
        bool isEncrypted,
        uint256 count,
        uint256 totalCount
    );

    function __subscription_init(
        uint256 _defaultCredits,
        uint256 _renewalPeriod,
        address _trustedForwarder,
        WalletRegistry _wallet
    ) public initializer {
        walletRegistry = _wallet;
        defaultCredits = _defaultCredits;
        renewalPeriod = _renewalPeriod;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("Dapps")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        __Ownable_init(_trustedForwarder);
    }

    function _onlySuperAdmin() internal view {
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()),
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdmin(bytes32 _appID) internal view {
        address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin),
            "INVALID_SENDER"
        );
    }

    // function _superAdminOrDappAdminOrSendNotifRole(bytes32 _appID)
    //     internal
    //     view
    // {
    //     address appAdmin = getDappAdmin(_appID);
    //     require(
    //         _msgSender() == owner() ||
    //             _msgSender() == getSecondaryWalletAccount(owner()) ||
    //             _msgSender() == appAdmin ||
    //             _msgSender() == getSecondaryWalletAccount(appAdmin) ||
    //             accountRole[_msgSender()][_appID] == 1 ||
    //             accountRole[_msgSender()][_appID] == 3,
    //         "INVALID_SENDER"
    //     );
    // }

    function _superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(bytes32 _appID)
        internal
        view
    {
        address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                accountRole[_msgSender()][_appID] == 1 ||
                accountRole[_msgSender()][_appID] == 3 ||
                registeredDappContracts[_appID][_msgSender()],
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdminOrAddedAdmin(bytes32 _appID) internal view {
        address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                accountRole[_msgSender()][_appID] == 2 ||
                accountRole[_msgSender()][_appID] == 3,
            "INVALID_SENDER"
        );
    }

    function _isValidSenderOrRegDappContract(address _from, bytes32 _dappId) internal view {
        require(
            _msgSender() == _from ||
                _msgSender() == getSecondaryWalletAccount(_from) ||
                registeredDappContracts[_dappId][_msgSender()],
            "INVALID_SENDER"
        );
    }

    function addGasRestrictorAndGamification(
        GasRestrictor _gasRestrictor,
        Gamification _gamification
    ) external onlyOwner {
        gasRestrictor = _gasRestrictor;
        gamification = _gamification;
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (getPrimaryFromSecondary(user) == address(0)) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        getPrimaryFromSecondary(user)
                    );
                    require(u != 0, "0_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "0_GASBALANCE");
            }
        }
    }

    // -------------------- DAPP FUNCTIONS ------------------------

    // function addNewDapp(
    //     string memory _appName,
    //     address _appAdmin, //primary
    //     string memory _appUrl,
    //     string memory _appIcon,
    //     string memory _appCoverImage,
    //     string memory _appSmallDescription,
    //     string memory _appLargeDescription,
    //     string[] memory _appScreenshots,
    //     string[] memory _appCategory,
    //     string[] memory _appTags,
    //     string[] memory _appSocial,
    //     bool isOauthUser
    // ) external GasNotZero(_msgSender(), isOauthUser) {
    //     uint256 gasLeftInit = gasleft();
    //     require(_appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
    //     require(_appScreenshots.length < 6, "SURPASSED IMAGE LIMIT");
    //     require(_appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
    //     require(_appTags.length < 8, "SURPASSED TAG LIMIT");

    //     checkFirstApp();
    //     _addNewDapp(
    //         _appName,
    //         _appAdmin,
    //         _appUrl,
    //         _appIcon,
    //         _appCoverImage,
    //         _appSmallDescription,
    //         _appLargeDescription,
    //         _appScreenshots,
    //         _appCategory,
    //         _appTags,
    //         _appSocial
    //     );

    //     _updateGaslessData(gasLeftInit);
    // }

    // function _addNewDapp(
    //     string memory _appName,
    //     address _appAdmin, //primary
    //     string memory _appUrl,
    //     string memory _appIcon,
    //     string memory _appCoverImage,
    //     string memory _appSmallDescription,
    //     string memory _appLargeDescription,
    //     string[] memory _appScreenshots,
    //     string[] memory _appCategory,
    //     string[] memory _appTags,
    //     string[] memory _appSocial
    // ) internal {
    //     bytes32 _appID;
    //     Dapp memory dapp = Dapp({
    //         appName: _appName,
    //         appId: _appID,
    //         appAdmin: _appAdmin,
    //         appUrl: _appUrl,
    //         appIcon: _appIcon,
    //         appCoverImage: _appCoverImage,
    //         appSmallDescription: _appSmallDescription,
    //         appLargeDescription: _appLargeDescription,
    //         appScreenshots: _appScreenshots,
    //         appCategory: _appCategory,
    //         appTags: _appTags,
    //         appSocial: _appSocial,
    //         isVerifiedDapp: false,
    //         credits: defaultCredits,
    //         renewalTimestamp: block.timestamp  });
    //     _appID = keccak256(
    //         abi.encode(
    //             dapp,
    //             block.number,
    //             _msgSender(),
    //             dappsCount,
    //             block.chainid
    //         )
    //     );
    //     dapp.appId = _appID;

    //     dapps[_appID] = dapp;
    //     isValidList[_appID][listsOfDappCount[_appID]++] = true;
    //     emit NewAppRegistered(_appID, _appAdmin, _appName, ++dappsCount);
    // }

    function addNewDapp(
        Dapp memory _dapp,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();
        require(_dapp.appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
        require(_dapp.appScreenshots.length < 6, "SURPASSED IMAGE LIMIT");
        require(_dapp.appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
        require(_dapp.appTags.length < 8, "SURPASSED TAG LIMIT");

        checkFirstApp();
        _addNewDapp(
            _dapp,
            false
        );

        _updateGaslessData(gasLeftInit);
    }

    function _addNewDapp(
        Dapp memory _dapp,
        bool _isAdmin
    ) internal {
        bytes32 _appID;
        Dapp memory dapp = Dapp({
            appName: _dapp.appName,
            appId: _appID,
            appAdmin: _dapp.appAdmin,
            appUrl: _dapp.appUrl,
            appIcon: _dapp.appIcon,
            appCoverImage: _dapp.appCoverImage,
            appSmallDescription: _dapp.appSmallDescription,
            appLargeDescription: _dapp.appLargeDescription,
            appScreenshots: _dapp.appScreenshots,
            appCategory: _dapp.appCategory,
            appTags: _dapp.appTags,
            appSocial: _dapp.appSocial,
            isVerifiedDapp: false,
            credits: defaultCredits,
            renewalTimestamp: block.timestamp
        });
        if(!_isAdmin)
            _appID = keccak256(
                abi.encode(dapp, block.number, _msgSender(), dappsCount, block.chainid)
            );
        else
            _appID = _dapp.appId;
        dapp.appId = _appID;

        dapps[_appID] = dapp;
        isValidList[_appID][listsOfDappCount[_appID]++] = true;
        emit NewAppRegistered(_appID, _dapp.appAdmin, _dapp.appName, ++dappsCount);
    }

    function addNewDappOnNewChain(
        Dapp memory _dapp
    ) external onlySuperAdmin {
        // uint256 gasLeftInit = gasleft();
        require(_dapp.appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
        require(_dapp.appScreenshots.length < 6, "SURPASSED IMAGE LIMIT");
        require(_dapp.appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
        require(_dapp.appTags.length < 8, "SURPASSED TAG LIMIT");
        require(_dapp.appId != "", "INVALID_APP_ID");
        // checkFirstApp();
        _addNewDapp(
            _dapp,
            true
        );

        // _updateGaslessData(gasLeftInit);
    }

    function checkFirstApp() internal {
        address primary = getPrimaryFromSecondary(_msgSender());
        if (primary != address(0)) {
            if (appCountUser[primary] == 0) {
                // add 5 karma points of primarywallet
                gamification.addKarmaPoints(primary, 5);
            }
            appCountUser[primary]++;
        } else {
            if (appCountUser[_msgSender()] == 0) {
                // add 5 karma points of _msgSender()
                gamification.addKarmaPoints(_msgSender(), 5);
            }
            appCountUser[_msgSender()]++;
        }
    }

    function changeDappAdmin(
        bytes32 _appId,
        address _newAdmin,
        bool isOauthUser
    )
        external
        superAdminOrDappAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID_DAPP");
        require(_newAdmin != address(0), "INVALID_OWNER");
        dapps[_appId].appAdmin = _newAdmin;

        // if (msg.sender == trustedForwarder)
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        _updateGaslessData(gasLeftInit);
    }

    function updateDapp(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        string[] memory _appImages, // [icon, cover_image]
        // string memory _appSmallDescription,
        // string memory _appLargeDescription,
        string[] memory _appDesc, // [small_desc, large_desc]
        string[] memory _appScreenshots,
        string[] memory _appCategory,
        string[] memory _appTags,
        string[] memory _appSocial, // [twitter_url]
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(_appImages.length == 2, "IMG_LIMIT_EXCEED");
        require(_appScreenshots.length < 6, "SS_LIMIT_EXCEED");
        require(_appCategory.length < 8, "CAT_LIMIT_EXCEED");
        require(_appTags.length < 8, "TAG_LIMIT_EXCEED");
        require(_appDesc.length == 2, "DESC_LIMIT_EXCEED");

        // _updateDappTextInfo(_appId, _appName, _appUrl, _appSmallDescription, _appLargeDescription, _appCategory, _appTags, _appSocial);
        _updateDappTextInfo(
            _appId,
            _appName,
            _appUrl,
            _appDesc,
            _appCategory,
            _appTags,
            _appSocial
        );
        _updateDappImageInfo(_appId, _appImages, _appScreenshots);

        // if(isTrustedForwarder(msg.sender)) {
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        // }
        _updateGaslessData(gasLeftInit);
    }

    function _updateDappTextInfo(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        // string memory _appSmallDescription,
        // string memory _appLargeDescription,
        string[] memory _appDesc,
        string[] memory _appCategory,
        string[] memory _appTags,
        string[] memory _appSocial
    ) internal {
        Dapp storage dapp = dapps[_appId];
        require(dapp.appAdmin != address(0), "INVALID_DAPP");
        if (bytes(_appName).length != 0) dapp.appName = _appName;
        if (bytes(_appUrl).length != 0) dapp.appUrl = _appUrl;
        if (bytes(_appDesc[0]).length != 0)
            dapp.appSmallDescription = _appDesc[0];
        if (bytes(_appDesc[1]).length != 0)
            dapp.appLargeDescription = _appDesc[1];
        // if(_appCategory.length != 0)
        dapp.appCategory = _appCategory;
        // if(_appTags.length != 0)
        dapp.appTags = _appTags;
        // if(_appSocial.length != 0)
        dapp.appSocial = _appSocial;
    }

    function _updateDappImageInfo(
        bytes32 _appId,
        string[] memory _appImages,
        string[] memory _appScreenshots
    ) internal {
        Dapp storage dapp = dapps[_appId];
        // if(bytes(_appImages[0]).length != 0)
        dapp.appIcon = _appImages[0];
        // if(bytes(_appImages[1]).length != 0)
        dapp.appCoverImage = _appImages[1];
        // if(_appScreenshots.length != 0)
        dapp.appScreenshots = _appScreenshots;

        emit AppUpdated(_appId);
    }

    function removeDapp(bytes32 _appId, bool isOauthUser)
        external
        superAdminOrDappAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID_DAPP");
        if (dapps[_appId].isVerifiedDapp) --verifiedDappsCount;
        delete dapps[_appId];
        --dappsCount;

        emit AppRemoved(_appId, dappsCount);

        _updateGaslessData(gasLeftInit);
    }

    function createDappList(
        bytes32 appId,
        string memory listName,
        bool isOauthUser
    )
        public
        GasNotZero(_msgSender(), isOauthUser)
        superAdminOrDappAdminOrAddedAdmin(appId)
    {
        uint id = listsOfDappCount[appId];
        isValidList[appId][id] = true;
        listsOfDapp[appId][id] =  List(id, listName);
        emit ListCreated(appId, listsOfDappCount[appId]++);

    }


    function addOrRemoveSubscriberToList(
        bytes32 appId, 
        address subscriber, 
        uint listID, 
        bool addOrRemove, 
        bool isOauthUser
    ) public GasNotZero(_msgSender(), isOauthUser) superAdminOrDappAdminOrAddedAdmin(appId) {
        
        require(isSubscribed[appId][0][subscriber] == true, "address not subscribed");
        require(isValidList[appId][listID] == true, "not valid list");

        isSubscribed[appId][listID][subscriber] = addOrRemove;

        if(addOrRemove) {
            listUserCount[appId][listID]++;
            emit UserAddedToList(appId, subscriber, listID);
        }
        else {
            listUserCount[appId][listID]--;
             emit UserRemovedFromList(appId, subscriber, listID);

        }
    }

    function updateRegDappContract(
        bytes32 _dappId,
        address _dappContractAddress,
        bool _status
    ) external superAdminOrDappAdmin(_dappId) {
        require(registeredDappContracts[_dappId][_dappContractAddress] != _status, "UNCHANGED");
        registeredDappContracts[_dappId][_dappContractAddress] = _status;
        if(_status)
            ++regDappContractsCount;
        else
            --regDappContractsCount;
    }

    // function subscribeToDappByContract(
    //     address user,
    //     bytes32 appID,
    //     bool subscriptionStatus,
    //     uint256[] memory _lists
    // ) external 
    // isRegisteredDappContract(appID)
    // {
    //     _subscribeToDappInternal(user, appID, subscriptionStatus, _lists);
    // }

    // function _subscribeToDappInternal(
    //     address user,
    //     bytes32 appID,
    //     bool subscriptionStatus,
    //     uint256[] memory _lists
    // ) internal {
    //     require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");

    //     if (_lists.length == 0) {
    //         require(
    //             isSubscribed[appID][0][user] != subscriptionStatus,
    //             "UNCHANGED"
    //         );
    //         _subscribeToDapp(user, appID, 0, subscriptionStatus);
    //     } else {
    //         if (isSubscribed[appID][0][user] == false) {
    //             _subscribeToDapp(user, appID, 0, true);
    //         }

    //         for (uint256 i = 0; i < _lists.length; i++) {
    //             _subscribeToDapp(user, appID, _lists[i], subscriptionStatus);
    //         }
    //     }
    // }

    function subscribeToDapp(
        address user,
        bytes32 appID,
        bool subscriptionStatus,
        bool isOauthUser,
        uint256[] memory _lists
    ) external 
    isValidSenderOrRegDappContract(user, appID) 
    GasNotZero(_msgSender(), isOauthUser) 
    {
        uint256 gasLeftInit = gasleft();
        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");

        if (_lists.length == 0) {
            require(
                isSubscribed[appID][0][user] != subscriptionStatus,
                "UNCHANGED"
            );
            _subscribeToDapp(user, appID, 0, subscriptionStatus);
        } else {
            if (isSubscribed[appID][0][user] == false) {
                _subscribeToDapp(user, appID, 0, true);
            }

            for (uint256 i = 0; i < _lists.length; i++) {
                _subscribeToDapp(user, appID, _lists[i], subscriptionStatus);
            }
        }
        // _subscribeToDappInternal(user, appID, subscriptionStatus, _lists);

        _updateGaslessData(gasLeftInit);
    }

    function _subscribeToDapp(
        address user,
        bytes32 appID,
        uint256 listID,
        bool subscriptionStatus
    ) internal {
        require(isValidList[appID][listID] == true, "not valid list");
        isSubscribed[appID][listID][user] = subscriptionStatus;

        address appAdmin = dapps[appID].appAdmin;

        if (listID == 0) {
            if (subscriptionStatus) {

                if (dapps[appID].isVerifiedDapp && !hasPreviouslysubscribed[appID][user] && dapps[appID].credits != 0) {
                    string memory message; 
                    string memory cta; 
                    string memory butonN;
                  
                        (message, cta, butonN) = gamification.getWelcomeMessage(appID);

                    // (string memory message,string memory cta, string memory butonN) = gamification.welcomeMessage(appID);
                    _sendAppNotification(
                        appID,
                        user,
                        message,
                        butonN,
                        cta,
                        false
                    );
                    hasPreviouslysubscribed[appID][user] = true;

                }
                uint256 subCountUser = ++subscriberCountUser[user];
                uint256 subCountDapp = ++subscriberCount[appID];
                emit AppSubscribed(
                    appID,
                    user,
                    subCountDapp,
                    ++noOfSubscribers
                );
                listUserCount[appID][0]++;
                subscriberCountUser[user]++;

                if (subCountDapp == 100) {
                    // add 10 karma point to app admin

                    gamification.addKarmaPoints(appAdmin, 10);
                } else if (subCountDapp == 500) {
                    // add 50 karma point to app admin
                    gamification.addKarmaPoints(appAdmin, 50);
                } else if (subCountDapp == 1000) {
                    // add 100 karma point to app admin

                    gamification.addKarmaPoints(appAdmin, 100);
                }

                if (subCountUser == 0) {
                    // add 1 karma point to subscriber
                    gamification.addKarmaPoints(user, 1);
                } else if (subCountUser == 5) {
                    // add 5 karma points to subscriber
                    gamification.addKarmaPoints(user, 5);
                }
            } else {
                listUserCount[appID][0]--;

                uint256 subCountUser = --subscriberCountUser[user];
                emit AppUnSubscribed(
                    appID,
                    user,
                    --subscriberCount[appID],
                    --noOfSubscribers
                );
                if (subCountUser == 0) {
                    // remove 1 karma point to app admin
                    gamification.removeKarmaPoints(user, 1);
                } else if (subCountUser == 4) {
                    // remove 5 karma points to app admin
                    gamification.removeKarmaPoints(user, 5);
                }
                // if (subCountDapp == 99) {
                //     // remove 10 karma point
                //     gamification.removeKarmaPoints(dapps[appID].appAdmin, 10);
                // } else if (subCountDapp == 499) {
                //     // remove 50 karma point
                //     gamification.removeKarmaPoints(dapps[appID].appAdmin, 50);
                // } else if (subCountDapp == 999) {
                //     // remove 100 karma point
                //     gamification.removeKarmaPoints(dapps[appID].appAdmin, 100);
                // }
            }
        } else {
            if (subscriptionStatus) {
                listUserCount[appID][listID]++;
            } else {
                listUserCount[appID][listID]--;
            }
        }

        // if (address(0) != getSecondaryWalletAccount(user)) {
        //     isSubscribed[appID][
        //         getSecondaryWalletAccount(user)
        //     ] = subscriptionStatus;
        // }
    }

    // function subscribeToDapp(
    //     address user,
    //     bytes32 appID,
    //     bool subscriptionStatus
    // ) external onlyOwner {
    //     require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
    //     require(isSubscribed[appID][user] != subscriptionStatus, "UNCHANGED");

    //     _subscribeToDapp(user, appID, subscriptionStatus);
    // }

    // function _subscribeToDapp(
    //     address user,
    //     bytes32 appID,
    //     bool subscriptionStatus
    // ) internal {
    //     isSubscribed[appID][user] = subscriptionStatus;

    //     if (subscriptionStatus)
    //         emit AppSubscribed(appID, user, ++subCountDapp, ++noOfSubscribers);
    //     else
    //         emit AppUnSubscribed(appID, user, --subCountDapp, --noOfSubscribers);

    //     if (address(0) != getSecondaryWalletAccount(user)) {
    //         isSubscribed[appID][
    //             getSecondaryWalletAccount(user)
    //         ] = subscriptionStatus;
    //     }
    // }

    // function subscribeWithPermit(
    //     address user,
    //     bytes32 appID,
    //     uint256[] memory _lists,
    //     bool subscriptionStatus,
    //     uint256 deadline,
    //     bytes32 r,
    //     bytes32 s,
    //     uint8 v
    // ) external {
    //     require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
    //     // require(isSubscribed[appID][user] != subscriptionStatus, "UNCHANGED");

    //     require(user != address(0), "ZERO_ADDRESS");
    //     require(deadline >= block.timestamp, "EXPIRED");

    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             "\x19\x01",
    //             DOMAIN_SEPARATOR,
    //             keccak256(
    //                 abi.encode(
    //                     SUBSC_PERMIT_TYPEHASH,
    //                     user,
    //                     appID,
    //                     subscriptionStatus,
    //                     nonce[user]++,
    //                     deadline
    //                 )
    //             )
    //         )
    //     );

    //     address recoveredUser = ecrecover(digest, v, r, s);
    //     require(
    //         recoveredUser != address(0) &&
    //             (recoveredUser == user ||
    //                 recoveredUser == getSecondaryWalletAccount(user)),
    //         "INVALID_SIGN"
    //     );

    //     if (_lists.length == 0) {
    //         require(
    //             isSubscribed[appID][0][user] != subscriptionStatus,
    //             "UNCHANGED"
    //         );
    //         _subscribeToDapp(user, appID, 0, subscriptionStatus);
    //     } else {
    //         if (isSubscribed[appID][0][user] == false) {
    //             _subscribeToDapp(user, appID, 0, true);
    //         }

    //         for (uint256 i = 0; i < _lists.length; i++) {
    //             _subscribeToDapp(user, appID, _lists[i], subscriptionStatus);
    //         }
    //     }
    // }

    function appVerification(
        bytes32 appID,
        bool verificationStatus,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) onlySuperAdmin {
        uint256 gasLeftInit = gasleft();

        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        // require(appID < dappsCount, "INVALID DAPP ID");
        if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            verificationStatus
        ) {
            verifiedDappsCount++;
            dapps[appID].isVerifiedDapp = verificationStatus;
        } else if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            !verificationStatus
        ) {
            verifiedDappsCount--;
            dapps[appID].isVerifiedDapp = verificationStatus;
        }

        _updateGaslessData(gasLeftInit);
    }

    function getDappAdmin(bytes32 _dappId) public view returns (address) {
        return dapps[_dappId].appAdmin;
    }

    // -------------------- WALLET FUNCTIONS -----------------------
    function addAccountsRole(
        bytes32 appId,
        address account, // primary address
        uint8 _role, // 0 means no role, 1 meaning only notif, 2 meaning only add admin, 3 meaning both
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[appId].appAdmin != address(0), "INVALID DAPP ID");
        require(dapps[appId].appAdmin != account, "IS_SUPERADMIN");
        require(_role < 4, "INVALID_ROLE");
        require(_role != accountRole[account][appId], "SAME_ROLE");

        accountRole[account][appId] = _role;
        accountRole[getSecondaryWalletAccount(account)][appId] = _role;

        emit AppAdmin(appId, getDappAdmin(appId), account, _role);

        _updateGaslessData(gasLeftInit);
    }

    // primary wallet address.
    function sendAppNotification(
        bytes32 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta,
        bool _isEncrypted,
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID DAPP ID");
        require(dapps[_appId].credits != 0, "0_CREDITS");
        require(
            isSubscribed[_appId][0][walletAddress] == true,
            "NOT_SUBSCRIBED"
        );

        if (notificationsOf[walletAddress].length == 0) {
            // add 1 karma point
            gamification.addKarmaPoints(walletAddress, 1);
        }

        _sendAppNotification(
            _appId,
            walletAddress,
            _message,
            buttonName,
            _cta,
            _isEncrypted
        );

        _updateGaslessData(gasLeftInit);
    }

    function _sendAppNotification(
        bytes32 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta,
        bool _isEncrypted
    ) internal {
        Notification memory notif = Notification({
            appID: _appId,
            walletAddressTo: walletAddress,
            message: _message,
            buttonName: buttonName,
            cta: _cta,
            timestamp: block.timestamp,
            isEncrypted: _isEncrypted
        });

        notificationsOf[walletAddress].push(notif);

        emit NewNotification(
            _appId,
            walletAddress,
            _message,
            buttonName,
            _cta,
            _isEncrypted,
            ++notificationsCount[_appId],
            ++noOfNotifications
        );
        --dapps[_appId].credits;
    }

    // // primary wallet address.
    // function sendAppNotification(
    //     bytes32 _appId,
    //     address walletAddress,
    //     string memory _message,
    //     string memory buttonName,
    //     string memory _cta,
    //     bool _isEncrypted
    // ) external onlyOwner {
    //     require(dapps[_appId].appAdmin != address(0), "INVALID DAPP ID");
    //     require(dapps[_appId].credits != 0, "NOT_ENOUGH_CREDITS");
    //     // require(isSubscribed[_appId][walletAddress] == true, "NOT_SUBSCRIBED");

    //     _sendAppNotification(_appId, walletAddress, _message, buttonName, _cta, _isEncrypted);
    // }

    // function _sendAppNotification(
    //     bytes32 _appId,
    //     address walletAddress,
    //     string memory _message,
    //     string memory buttonName,
    //     string memory _cta,
    //     bool _isEncrypted
    // ) internal {
    //     Notification memory notif = Notification({
    //         appID: _appId,
    //         walletAddressTo: walletAddress,
    //         message: _message,
    //         buttonName: buttonName,
    //         cta: _cta,
    //         timestamp: block.timestamp,
    //         isEncrypted: _isEncrypted
    //     });

    //     notificationsOf[walletAddress].push(notif);

    //     emit NewNotification(
    //         _appId,
    //         walletAddress,
    //         _message,
    //         buttonName,
    //         _cta,
    //         _isEncrypted,
    //         ++notificationsCount[_appId],
    //         ++noOfNotifications
    //     );
    //     --dapps[_appId].credits;
    // }

    function getNotificationsOf(address user)
        external
        view
        returns (Notification[] memory)
    {
        return notificationsOf[user];
    }

    function getSecondaryWalletAccount(address _account)
        public
        view
        returns (address)
    {
        (address account, , ) = walletRegistry.userWallets(_account);

        return account;
    }

    function getPrimaryFromSecondary(address _account)
        public
        view
        returns (address)
    {
        return walletRegistry.getPrimaryFromSecondary(_account);
    }

    function getDapp(bytes32 dappId) public view returns (Dapp memory) {
        return dapps[dappId];
    }

    // function upgradeCreditsByAdmin( bytes32 dappId,uint amount ) external onlySuperAdmin() {
    //     dapps[dappId].credits = defaultCredits + amount;
    // }

    // function renewCredits(bytes32 dappId, bool isOauthUser)
    //     external
    //     superAdminOrDappAdminOrAddedAdmin(dappId)
    //     GasNotZero(_msgSender(), isOauthUser)
    // {
    //     uint256 gasLeftInit = gasleft();

    //     require(dapps[dappId].appAdmin != address(0), "INVALID_DAPP");
    //     require(
    //         block.timestamp - dapps[dappId].renewalTimestamp == renewalPeriod,
    //         "RPNC"
    //     ); // RENEWAL_PERIOD_NOT_COMPLETED
    //     dapps[dappId].credits = defaultCredits;

    //     _updateGaslessData(gasLeftInit);
    // }

    // function deleteWallet(address _account) external onlySuperAdmin {
    //     require(userWallets[_msgSender()].account != address(0), "NO_ACCOUNT");
    //     delete userWallets[_account];
    //     delete getPrimaryFromSecondary[_account];
    // }
    // ------------------------ TELEGRAM FUNCTIONS -----------------------------------

    // function getTelegramChatID(address userWallet) public view returns (string memory) {
    //     return telegramChatID[userWallet];
    // }

    // function setDomainSeparator() external onlyOwner {
    //     DOMAIN_SEPARATOR = keccak256(abi.encode(
    //         EIP712_DOMAIN_TYPEHASH,
    //         keccak256(bytes("Dapps")),
    //         keccak256(bytes("1")),
    //         chainId,
    //         address(this)
    //     ));
    // }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }

    //    function createWallet(
    //     address _account,
    //     string calldata _encPvtKey,
    //     string calldata _publicKey,
    //     string calldata oAuthEncryptedUserId,
    //     bool isOauthUser,
    //     address referer
    // ) external {

    // }

    // function userWallets(address _account)
    //     public
    //     view
    //     returns (address, string memory, string memory)
    // {
    //    (address account, string memory encPvKey,string memory pubKey) =  walletRegistry.userWallets(_account);

    //    return (account, encPvKey,pubKey );
    // }
}