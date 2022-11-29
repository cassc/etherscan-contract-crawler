// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../UnifarmAccountsUpgradeable.sol";

contract UnifarmSubscription is Initializable, OwnableUpgradeable {
    // --------------------- DAPPS  -----------------------
    UnifarmAccountsUpgradeable public unifarmAccounts;
    uint256 public dappId; // dappID for this decentralized messaging application (should be fixed)
    address public superAdmin; // dapps admin, has access to add or remove any dapp admin.

    struct Dapp {
        string appName;
        uint256 appId;
        address appAdmin; //primary
        string appIcon;
        string appSmallDescription;
        string appLargeDescription;
        string[] appScreenshots;
        string appCategory;
        string appTags;
        bool isVerifiedDapp; // true or false
    }


    struct Notification {
        uint appID;
        address walletAddressTo; // primary
        string message;
        string buttonName;
        string cta;
        uint timestamp;
    }
    // dappId => address => bool(true/false)
    mapping(uint256 => mapping(address => bool)) public isGovernor;

    // dappId => address => bool(true/false)
    mapping(uint256 => mapping(address => bool)) public isSubscribed;
    
    mapping(address => Notification[]) public notificationsOf; 
    // dappID => dapp
    mapping(uint256 => Dapp) public dapps;

    uint256 public dappsCount;
    uint256 public verifiedDappsCount;

     event newAppRegistered(
       uint256 appID, 
       address appAdmin, 
       string appName
    );

    event AppAdmin(
        uint256 appID, 
        address appAdmin, 
        address admin, 
        bool status
    );

    event AppSubscribed(
        uint256 appID, 
        address subscriber
    );
    event AppUnSubscribed(
        uint256 appID, 
        address subscriber
    );

    event newNotifiaction ( uint256 appId, address walletAddress,string message, string buttonName , string cta);
    

    modifier onlySuperAdmin() {
        require(
            _msgSender() == superAdmin ||
                _msgSender() ==
                unifarmAccounts.getSecondaryWalletAccount(superAdmin),
            "INVALID_SENDER"
        );
        _;
    }
    modifier superAdminOrDappAdmin(uint appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == superAdmin ||
            _msgSender() == unifarmAccounts.getSecondaryWalletAccount(superAdmin) || _msgSender() == appAdmin ||   _msgSender() == unifarmAccounts.getSecondaryWalletAccount(appAdmin)
        , "INVALID_SENDER");
        _;
    }

    

   modifier appAdminOrGovernorOrSuperAdmin(uint appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == superAdmin ||
            _msgSender() == unifarmAccounts.getSecondaryWalletAccount(superAdmin) || _msgSender() == appAdmin || 
            _msgSender() == unifarmAccounts.getSecondaryWalletAccount(appAdmin) ||  isGovernor[appID][_msgSender()] == true 
        , "INVALID_SENDER");
        _;
   }
    function __UnifarmSubscription_init(
        uint256 _dappId,
        UnifarmAccountsUpgradeable _unifarmAccounts,
        address _trustedForwarder,
        address _superAdmin
    ) public initializer {
        __Ownable_init(_trustedForwarder);
        unifarmAccounts = _unifarmAccounts;
        dappId = _dappId;
        superAdmin = _superAdmin;

        // __Pausable_init();
    }

    function _isGovernor(address _from, uint appId) internal view {
        // _msgSender() should be either primary (_from) or secondary wallet of _from
        require(
            isGovernor[appId][_from] == true,
            "INVALID_SENDER"
        );
    }

    // -------------------- DAPP FUNCTIONS ------------------------

    function addNewDapp(
        string memory _appName,
        address _appAdmin, //primary
        string memory _appIcon,
        string memory _appSmallDescription,
        string memory _appLargeDescription,
        string[] memory _appScreenshots,
        string memory _appCategory,
        string memory _appTags
    ) external {
        uint256 _appID = dappsCount;
        Dapp memory dapp = Dapp({
            appName: _appName,
            appId: _appID,
            appAdmin: _appAdmin,
            appIcon: _appIcon,
            appSmallDescription: _appSmallDescription,
            appLargeDescription: _appLargeDescription,
            appScreenshots: _appScreenshots,
            appCategory: _appCategory,
            appTags: _appTags,
            isVerifiedDapp: false
        });
        dapps[_appID] = dapp;

        emit newAppRegistered(_appID, _appAdmin, _appName);
        dappsCount++;
    }


    function subscribeToDapp(address user, uint appID, bool subscriptionStatus) external {
    require(appID <= dappsCount, "Invalid dapp id");
    require(dapps[appID].isVerifiedDapp == true, "unverified app");
     isSubscribed[appID][user] = subscriptionStatus;
     
     if(subscriptionStatus) {
         emit AppSubscribed(appID, user);

     }
     else {
         emit AppUnSubscribed(appID, user);
     }
    }

    function appVerification(uint256 appID, bool verificationStatus)
        external
        onlySuperAdmin
    {
        dapps[appID].isVerifiedDapp = verificationStatus;
        if (verificationStatus) {
            verifiedDappsCount++;
        } else {
            verifiedDappsCount--;
        }
    }

// newAdmin is primary wallet address
    function addAppAdmin(uint256 appID, address admin, bool status) external superAdminOrDappAdmin(appID) {
     
    isGovernor[appID][admin] = status; 
    isGovernor[appID][unifarmAccounts.getSecondaryWalletAccount(admin)] = status; 
    emit AppAdmin(appID, getDappAdmin(appID), admin, status);
     
    }


// primary wallet address. ?? 
    function sendAppNotification(uint _appId, address[] memory walletAddress, string memory _message, string memory buttonNAme, string memory _cta) external appAdminOrGovernorOrSuperAdmin(_appId)  {

        unchecked {
        for (uint i = 0; i < walletAddress.length; i++) {
    require(isSubscribed[_appId][walletAddress[i]] == true);       
    Notification memory notif = Notification({
    appID: _appId, 
    walletAddressTo: walletAddress[i],
    message: _message, 
    buttonName: buttonNAme, 
    cta: _cta,
    timestamp: block.timestamp
    });

    notificationsOf[walletAddress[i]].push(notif);
    emit newNotifiaction(_appId, walletAddress[i], _message,buttonNAme, _cta );
        }
         }
    }



    function getNotificationsOf(address user) external view returns(Notification[] memory){
        return notificationsOf[user];
    }

    function getDappAdmin(uint256 _dappId) public view returns (address) {
        return dapps[_dappId].appAdmin;
    }

    // -------------------- WALLET FUNCTIONS -----------------------
}