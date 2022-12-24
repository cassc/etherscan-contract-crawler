// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./GasRestrictor.sol";

contract UnifarmAccountsUpgradeable is Initializable, OwnableUpgradeable {
    uint256 public chainId;
    uint256 public defaultCredits;
    uint256 public renewalPeriod;
    GasRestrictor public gasRestrictor;

    // --------------------- DAPPS STORAGE -----------------------

    struct Role {
        bool sendNotificationRole;
        bool addAdminRole;
    }
    struct SecondaryWallet {
        address account;
        string encPvtKey;
        string publicKey;
    }

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
        bool isVerifiedDapp; // true or false
        uint256 credits;
        uint256 renewalTimestamp;
    }

    struct Notification {
        bytes32 appID;
        address walletAddressTo; // primary
        string message;
        string buttonName;
        string cta;
        uint256 timestamp;
        bool isEncrypted;
    }
    mapping(bytes32 => Dapp) public dapps;

    // all dapps count
    uint256 public dappsCount;
    uint256 public verifiedDappsCount;

    mapping(address => Notification[]) public notificationsOf;
    // dappId => count
    mapping(bytes32 => uint256) public notificationsCount;

    // dappId => count
    mapping(bytes32 => uint256) public subscriberCount;

    // dappID => dapp

    // address => dappId  => role
    mapping(address => mapping(bytes32 => Role)) public roleOfAddress;

    // dappId => address => bool(true/false)
    mapping(bytes32 => mapping(address => bool)) public isSubscribed;

    // userAddress  => Wallet
    mapping(address => SecondaryWallet) public userWallets;
    // string => userWallet for email users
    mapping(string => SecondaryWallet) public oAuthUserWallets;

    // secondary to primary wallet mapping to get primary wallet from secondary
    mapping(address => address) public getPrimaryFromSecondary;

    modifier onlySuperAdmin() {
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()),
            "INVALID_SENDER"
        );
        _;
    }
    modifier isValidSender(address from) {
        require(
            _msgSender() == from ||
                _msgSender() == getSecondaryWalletAccount(from),
            "INVALID_SENDER"
        );
        _;
    }

    modifier superAdminOrDappAdmin(bytes32 appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin),
            "INVALID_SENDER"
        );
        _;
    }

    modifier superAdminOrDappAdminOrAddedAdmin(bytes32 appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                roleOfAddress[_msgSender()][appID].addAdminRole == true,
            "INVALID_SENDER"
        );
        _;
    }

    modifier superAdminOrDappAdminOrSendNotifRole(bytes32 appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                roleOfAddress[_msgSender()][appID].sendNotificationRole == true,
            "INVALID_SENDER"
        );
        _;
    }

    modifier GasNotZero(address user, bool isOauthUser) {
      _gasNotZero(user, isOauthUser);
      _;

    }

    event NewAppRegistered(
        bytes32 appID,
        address appAdmin,
        string appName,
        uint256 dappCount
    );

    event AppUpdated(
        bytes32 appID
    );

    event AppRemoved(
        bytes32 appID,
        uint256 dappCount
    );

    event AppAdmin(bytes32 appID, address appAdmin, address admin, uint8 role);

    event AppSubscribed(bytes32 appID, address subscriber, uint256 count);

    event AppUnSubscribed(bytes32 appID, address subscriber, uint256 count);

    event NewNotification(
        bytes32 appId,
        address walletAddress,
        string message,
        string buttonName,
        string cta,
        bool isEncrypted,
        uint256 count
    );

    function __UnifarmAccounts_init(
        uint256 _chainId,
        uint256 _defaultCredits,
        uint256 _renewalPeriod,
        address _trustedForwarder
    ) public initializer {
        chainId = _chainId;
        defaultCredits = _defaultCredits;
        renewalPeriod = _renewalPeriod;
        __Ownable_init(_trustedForwarder);
    }

    function addGasRestrictor(GasRestrictor _gasRestrictor) external onlyOwner {
        gasRestrictor = _gasRestrictor;
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if(trustedForwarder == msg.sender) {
         if (!isOauthUser) {
            if (getPrimaryFromSecondary[user] == address(0)) {
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(
                    getPrimaryFromSecondary[user]
                );
                require(u != 0, "NOT_ENOUGH_GASBALANCE");
            }
        } else {
            (, , uint256 u) = gasRestrictor.gaslessData(user);
            require(u != 0, "NOT_ENOUGH_GASBALANCE");
        } 
        }
    }

    // -------------------- DAPP FUNCTIONS ------------------------

    function addNewDapp(
        string memory _appName,
        address _appAdmin, //primary
        string memory _appUrl,
        string memory _appIcon,
        string memory _appCoverImage,
        string memory _appSmallDescription,
        string memory _appLargeDescription,
        string[] memory _appScreenshots,
        string[] memory _appCategory,
        string[] memory _appTags,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();
        require(_appAdmin != address(0), "0 address");
        require(_appScreenshots.length < 6, "surpassed image limit");
        require(_appCategory.length < 8, "surpassed image limit");
        require(_appTags.length < 8, "surpassed image limit");

        _addNewDapp(
            _appName,
            _appAdmin,
            _appUrl,
            _appIcon,
            _appCoverImage,
            _appSmallDescription,
            _appLargeDescription,
            _appScreenshots,
            _appCategory,
            _appTags
        );
        dappsCount++;
        if (msg.sender == trustedForwarder) {
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        }
    }

    function _addNewDapp(
        string memory _appName,
        address _appAdmin, //primary
        string memory _appUrl,
        string memory _appIcon,
        string memory _appCoverImage,
        string memory _appSmallDescription,
        string memory _appLargeDescription,
        string[] memory _appScreenshots,
        string[] memory _appCategory,
        string[] memory _appTags
    ) internal {
        bytes32 _appID;
        Dapp memory dapp = Dapp({
            appName: _appName,
            appId: _appID,
            appAdmin: _appAdmin,
            appUrl: _appUrl,
            appIcon: _appIcon,
            appCoverImage: _appCoverImage,
            appSmallDescription: _appSmallDescription,
            appLargeDescription: _appLargeDescription,
            appScreenshots: _appScreenshots,
            appCategory: _appCategory,
            appTags: _appTags,
            isVerifiedDapp: false,
            credits: defaultCredits,
            renewalTimestamp: block.timestamp
        });
        _appID = keccak256(
            abi.encode(dapp, block.number, _msgSender(), dappsCount, chainId)
        );
        dapp.appId = _appID;

        dapps[_appID] = dapp;
        emit NewAppRegistered(_appID, _appAdmin, _appName, dappsCount++);
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

        require(_newAdmin != address(0), "INVALID_OWNER");
        dapps[_appId].appAdmin = _newAdmin;
        
        if (msg.sender == trustedForwarder)
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    }

    function updateDapp(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        string[] memory _appImages,     // [icon, cover_image]
        string memory _appSmallDescription,
        string memory _appLargeDescription,
        string[] memory _appScreenshots,
        string[] memory _appCategory,
        string[] memory _appTags,
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

        _updateDappTextInfo(_appId, _appName, _appUrl, _appSmallDescription, _appLargeDescription, _appCategory, _appTags);
        _updateDappImageInfo(_appId, _appImages, _appScreenshots);

        if (msg.sender == trustedForwarder)
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    }

    function _updateDappTextInfo(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        string memory _appSmallDescription,
        string memory _appLargeDescription,
        string[] memory _appCategory,
        string[] memory _appTags
    ) internal {
        Dapp storage dapp = dapps[_appId];
        if(bytes(_appName).length != 0)
            dapp.appName = _appName;
        if(bytes(_appUrl).length != 0)
            dapp.appUrl = _appUrl;
        if(bytes(_appSmallDescription).length != 0)
            dapp.appSmallDescription = _appSmallDescription;
        if(bytes(_appLargeDescription).length != 0)
            dapp.appLargeDescription = _appLargeDescription;
        if(_appCategory.length != 0)
            dapp.appCategory = _appCategory;
        if(_appTags.length != 0)
            dapp.appTags = _appTags;
    }

    function _updateDappImageInfo(
        bytes32 _appId,
        string[] memory _appImages,
        string[] memory _appScreenshots
    ) internal {
        Dapp storage dapp = dapps[_appId];
        if(bytes(_appImages[0]).length != 0)
            dapp.appIcon = _appImages[0];
        if(bytes(_appImages[1]).length != 0)
            dapp.appCoverImage = _appImages[1];
        if(_appScreenshots.length != 0)
            dapp.appScreenshots = _appScreenshots;

        emit AppUpdated(_appId);
    }

    function removeDapp(
        bytes32 _appId,
        bool isOauthUser
    ) external superAdminOrDappAdmin(_appId) GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        if(dapps[_appId].isVerifiedDapp)
            --verifiedDappsCount;
        delete dapps[_appId];
        --dappsCount;

        emit AppRemoved(_appId, dappsCount);

        if (msg.sender == trustedForwarder) {
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        }
    }

    function subscribeToDapp(
        address user,
        bytes32 appID,
        bool subscriptionStatus,
        bool isOauthUser
    ) external isValidSender(user) GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();
        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        require(isSubscribed[appID][user] != subscriptionStatus, "UNCHANGED");

        isSubscribed[appID][user] = subscriptionStatus;

        if (subscriptionStatus) {
            subscriberCount[appID] += 1;
            emit AppSubscribed(appID, user, subscriberCount[appID]);
        } else {
            subscriberCount[appID] -= 1;
            emit AppUnSubscribed(appID, user, subscriberCount[appID]);
        }
        if (address(0) != getSecondaryWalletAccount(user)) {
            isSubscribed[appID][
                getSecondaryWalletAccount(user)
            ] = subscriptionStatus;
        }

        //    if(msg.sender == trustedForwarder) {
        gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        //    }
    }

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

        if (msg.sender == trustedForwarder) {
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        }
    }

    function getDappAdmin(bytes32 _dappId) public view returns (address) {
        return dapps[_dappId].appAdmin;
    }

    // -------------------- WALLET FUNCTIONS -----------------------

    function addAppAdmin(
        bytes32 appID,
        address admin, // primary address
        uint8 _role, // 0 meaning only notif, 1 meaning only add admin, 2 meaning both,
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(appID)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        require(_role < 3, "INAVLID ROLE");
        if (_role == 0) {
            roleOfAddress[admin][appID].addAdminRole = false;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .addAdminRole = false;
            roleOfAddress[admin][appID].sendNotificationRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .sendNotificationRole = true;
        } else if (_role == 1) {
            roleOfAddress[admin][appID].addAdminRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .addAdminRole = true;
            roleOfAddress[admin][appID].sendNotificationRole = false;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .sendNotificationRole = false;
        } else if (_role == 2) {
            roleOfAddress[admin][appID].addAdminRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .addAdminRole = true;
            roleOfAddress[admin][appID].sendNotificationRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .sendNotificationRole = true;
        }
        emit AppAdmin(appID, getDappAdmin(appID), admin, _role);
        if (msg.sender == trustedForwarder) {
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        }
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
    ) external superAdminOrDappAdminOrSendNotifRole(_appId)  GasNotZero(_msgSender(), isOauthUser){
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID DAPP ID");
        require(dapps[_appId].credits != 0, "NOT_ENOUGH_CREDITS");
        require(isSubscribed[_appId][walletAddress] == true, "NOT_SUBSCRIBED");

        _sendAppNotification(_appId, walletAddress, _message, buttonName, _cta, _isEncrypted);
        
        if (msg.sender == trustedForwarder) {
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        }
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
        // notificationsCount[_appId] += 1;
        emit NewNotification(
            _appId,
            walletAddress,
            _message,
            buttonName,
            _cta,
            _isEncrypted,
            ++notificationsCount[_appId]
        );
        --dapps[_appId].credits;
    }

    function createWallet(
        address _account,
        string calldata _encPvtKey,
        string calldata _publicKey,
        string calldata oAuthEncryptedUserId,
        bool isOauthUser
    ) external {
        if (!isOauthUser) {
            require(
                userWallets[_msgSender()].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            userWallets[_msgSender()] = wallet;
            getPrimaryFromSecondary[_account] = _msgSender();

            gasRestrictor.initUser(_msgSender(), _account, false);
        } else {
            require(
                oAuthUserWallets[oAuthEncryptedUserId].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            require(_msgSender() == _account, "Invalid_User");
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            oAuthUserWallets[oAuthEncryptedUserId] = wallet;
            // getPrimaryFromSecondary[_account] = _msgSender();

            gasRestrictor.initUser(_msgSender(), _account, true);
        }
    }

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
        return userWallets[_account].account;
    }

    function uintToBytes32(uint256 num) public pure returns (bytes32) {
        return bytes32(num);
    }

    function getDapp(bytes32 dappId) public view returns (Dapp memory) {
        return dapps[dappId];
    }

    // function upgradeCreditsByAdmin( bytes32 dappId,uint amount ) external onlySuperAdmin() {
    //     dapps[dappId].credits = defaultCredits + amount;
    // }

    function renewCredits(bytes32 dappId, bool isOauthUser)
        external
        superAdminOrDappAdminOrAddedAdmin(dappId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(
            block.timestamp - dapps[dappId].renewalTimestamp == renewalPeriod,
            "RENEWAL_PERIOD_NOT_COMPLETED"
        );
        dapps[dappId].credits = defaultCredits;

        if (msg.sender == trustedForwarder) {
            gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        }
    }

    // function deleteWallet(address _account) external onlySuperAdmin {
    //     require(userWallets[_msgSender()].account != address(0), "NO_ACCOUNT");
    //     delete userWallets[_account];
    //     delete getPrimaryFromSecondary[_account];
    // }
}