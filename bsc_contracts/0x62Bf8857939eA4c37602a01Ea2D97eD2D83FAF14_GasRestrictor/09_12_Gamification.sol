// import "./sdkInterFace/subscriptionModulesI.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./SubscriptionModule.sol";

contract Gamification is Initializable, OwnableUpgradeable {
 
    struct Reaction {
        string reactionName;
        uint256 count;
    }

    struct EbookDetails {
        string title;
        string summary;
        string assetFile;
        string assetSampleFile;
        string coverImage;
        bool isSendNotif;
        bool isShowApp;
        string aboutCompany;
        string aboutImage;
    }

    struct Message {
        address sender;
        bytes32 senderDappID; // encrypted using receiver's public key
        bytes32 receiverDappId;
        string textMessageEncryptedForReceiver; // encrypted using sender's public key
        string textMessageEncryptedForSender; // encrypted using sender's public key
        uint256 timestamp;
    }


    struct WelcomeMessage {
        string message;
        string cta;
        string buttonName;
    }

    struct EbookMessage {
        string message;
        string cta;
        string buttonName;
    }

    struct Token {
        bytes32 appId;
        address _tokenAddress;
        uint256 _tokenType; // ERC20, ERC721 (20, 721)
    }

    struct TokenNotif {
        bytes32 _id;
        string message;
        uint256 reactionCounts;
        address _token;
    }
    mapping(bytes32 => EbookMessage) public ebookMessage;
    mapping(bytes32 => WelcomeMessage) public welcomeMessage;

    // dappId => ebook
    mapping(bytes32 => EbookDetails) public ebooks;

    // from -> to -> messageID
    mapping(bytes32 => mapping(bytes32 => uint256)) public messageIdOfDapps; //
    uint256 public messageIdCount;
    mapping(uint256 => Message[]) public messages;

    mapping(address => bool) public isDappsContract;
    GasRestrictor public gasRestrictor;

    SubscriptionModule public subscriptionModule;

    mapping(address => uint256) public karmaPoints;
    //tokenNotifID => tokenNotif
    mapping(bytes32 => TokenNotif) public singleTokenNotif;
    // tokenNotifId=>react=>count
    mapping(bytes32 => mapping(string => uint256))
        public reactionsOfTokenNotifs;
    // tokenNotifId => user => reactionStatus;
    mapping(bytes32 => mapping(address => bool)) public reactionStatus;

    // string ReactionName => isValid bool
    mapping(string => bool) public isValidReaction;

    // appId => Tokens
    mapping(bytes32 => Token[]) public tokenOfVerifiedApp;
    // tokenAddress => tokenDetails
    mapping(address => Token) public tokenByTokenAddress;

    event NewTokenNotif(bytes32 appID, bytes32 _id, address token);

    event NewDappMessage(bytes32 from, bytes32 to, uint256 messageId);

    modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    modifier isDapp(address dapp) {
        require(isDappsContract[dapp] == true, "Not_registred_dapp");
        _;
    }
    modifier isValidApp(bytes32 dappId) {
        _isValidApp(dappId);
        _;
    }
    modifier onlySuperAdmin() {
        _onlySuperAdmin();
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

    function init_Gamification(
        address _subscriptionModule,
        address _trustedForwarder,
        GasRestrictor _gasRestrictor
    ) public initializer {
        subscriptionModule = SubscriptionModule(_subscriptionModule);
        isDappsContract[_subscriptionModule] = true;
        __Ownable_init(_trustedForwarder);
        gasRestrictor = _gasRestrictor;
    }

    function _isValidApp(bytes32 _appId) internal view {
        address a = subscriptionModule.getDappAdmin(_appId);
        require(a != address(0), "INVALID_DAPP");
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (
                    subscriptionModule.getPrimaryFromSecondary(user) == address(0)
                ) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        subscriptionModule.getPrimaryFromSecondary(user)
                    );
                    require(u != 0, "0_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "0_GASBALANCE");
            }
        }
    }

    function _onlySuperAdmin() internal view {
        require(
            _msgSender() == owner() ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(owner()),
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdmin(bytes32 _appID) internal view {
        address appAdmin = subscriptionModule.getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(appAdmin),
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdminOrAddedAdmin(bytes32 _appID) internal view {
        address appAdmin = subscriptionModule.getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(appAdmin) ||
                subscriptionModule.accountRole(_msgSender(), _appID) == 2 ||
                subscriptionModule.accountRole(_msgSender(), _appID) == 3,
            "INVALID_SENDER"
        );
    }

    function addDapp(address dapp) external onlyOwner {
        isDappsContract[dapp] = true;
    }

    function addKarmaPoints(address _for, uint256 amount)
        public
        isDapp(msg.sender)
    {
        karmaPoints[_for] = karmaPoints[_for] + amount;
    }

    function removeKarmaPoints(address _for, uint256 amount)
        public
        isDapp(msg.sender)
    {
        require(karmaPoints[_for] > amount, "not enough karma points");
        karmaPoints[_for] = karmaPoints[_for] - amount;
    }

    function sendNotifTokenHolders(
        bytes32 _appID,
        string memory _message,
        address _tokenAddress,
        bool isOAuthUser
    )
        public
        GasNotZero(_msgSender(), isOAuthUser)
        superAdminOrDappAdmin(_appID)
    {
        uint256 gasLeftInit = gasleft();
        address _token = tokenByTokenAddress[_tokenAddress]._tokenAddress;
        require(_token != address(0), "NOT_VERIFIED");
        require(
            tokenByTokenAddress[_tokenAddress].appId == _appID,
            "Not Token Of App"
        );
        // check if msg.sender is tokenAdmin/superAdmin

        bytes32 _tokenNotifID;
        _tokenNotifID = keccak256(
            abi.encode(block.number, _msgSender(), block.timestamp)
        );

        singleTokenNotif[_tokenNotifID] = TokenNotif(
            _tokenNotifID,
            _message,
            0,
            _tokenAddress
        );

        emit NewTokenNotif(_appID, _tokenNotifID, _token);

        _updateGaslessData(gasLeftInit);
    }

    function reactToTokenNotif(bytes32 tokenNotifId, string memory reaction)
        external
    {
        require(singleTokenNotif[tokenNotifId]._id == tokenNotifId, "WRONG_ID");
        require(
            reactionStatus[tokenNotifId][_msgSender()] == false,
            "WRONG_ID"
        );
        require(isValidReaction[reaction] == true, "WRONG_R");
        uint256 gasLeftInit = gasleft();

        uint256 _type = tokenByTokenAddress[
            singleTokenNotif[tokenNotifId]._token
        ]._tokenType;
        address token = singleTokenNotif[tokenNotifId]._token;
        if (_type == 20 || _type == 721) {
            require(IERC20(token).balanceOf(_msgSender()) > 0);
        }

        reactionsOfTokenNotifs[tokenNotifId][reaction]++;
        singleTokenNotif[tokenNotifId].reactionCounts++;

        reactionStatus[tokenNotifId][_msgSender()] = true;

        _updateGaslessData(gasLeftInit);
    }

    function addValidReactions(string memory _reaction)
        external
        onlySuperAdmin
    {
        isValidReaction[_reaction] = true;
    }

    function updateDappToken(
        bytes32 _appId,
        address[] memory _tokens,
        uint256[] memory _types // bool _isOauthUser
    ) external superAdminOrDappAdmin(_appId) isValidApp(_appId) {
        // onlySuperAdmin
        uint256 gasLeftInit = gasleft();

        require(_tokens.length == _types.length, "INVALID_PARAM");

        for (uint256 i = 0; i < _tokens.length; i++) {
            Token memory _t = Token(_appId, _tokens[i], _types[i]);
            tokenOfVerifiedApp[_appId].push(_t);
            tokenByTokenAddress[_tokens[i]] = _t;
        }

        _updateGaslessData(gasLeftInit);
    }

    function deleteDappToken(bytes32 _appId)
        external
        superAdminOrDappAdmin(_appId)
        isValidApp(_appId)
    {
        require(tokenOfVerifiedApp[_appId].length != 0, "No Token");

        delete tokenOfVerifiedApp[_appId];
    }

    function updateWelcomeMessage(
        bytes32 _appId,
        string memory _message,
        string memory _cta,
        string memory _buttonName
    ) public superAdminOrDappAdmin(_appId) isValidApp(_appId) {
        welcomeMessage[_appId].message = _message;
        welcomeMessage[_appId].buttonName = _buttonName;
        welcomeMessage[_appId].cta = _cta;
    }

    function updateEbookMessage(
        bytes32 _appId,
        string memory _message,
        string memory _cta,
        string memory _buttonName
    ) public superAdminOrDappAdmin(_appId) isValidApp(_appId) {
        ebookMessage[_appId].message = _message;
        ebookMessage[_appId].buttonName = _buttonName;
        ebookMessage[_appId].cta = _cta;
    }

    function sendMessageToDapp(
        bytes32 appFrom,
        bytes32 appTo,
        string memory encMessageForReceiverDapp,
        string memory enMessageForSenderDapp,
        bool isOAuthUser
    )
        public
        superAdminOrDappAdmin(appFrom)
        isValidApp(appFrom)
        isValidApp(appTo)
        GasNotZero(_msgSender(), isOAuthUser)
    {
        bool isVerified = subscriptionModule.getDapp(appFrom).isVerifiedDapp;
        // check isVerified Dapp OR Not
        require(isVerified == true, "App Not Verified");

        Message memory message = Message({
            sender: _msgSender(),
            senderDappID: appFrom,
            receiverDappId: appTo,
            textMessageEncryptedForReceiver: encMessageForReceiverDapp,
            textMessageEncryptedForSender: enMessageForSenderDapp,
            timestamp: block.timestamp
        });

        uint256 messageId = messageIdOfDapps[appFrom][appTo];
        if (messageId == 0) {
            messageId = ++messageIdCount;
            messageIdOfDapps[appFrom][appTo] = messageId;
            messageIdOfDapps[appTo][appFrom] = messageId;
        }
        messages[messageId].push(message);

        emit NewDappMessage(appFrom, appTo, messageId);
    }


    function updateEbook(
        bytes32 _appId,
        EbookDetails memory _ebookDetails,
        bool _isAuthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(_appId)
        GasNotZero(_msgSender(), _isAuthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(
            subscriptionModule.getDappAdmin(_appId) != address(0),
            "INVALID DAPP ID"
        );
        require(bytes(_ebookDetails.title).length != 0, "EMPTY_TITLE");
        EbookDetails memory ebookDetails = EbookDetails({
            title: _ebookDetails.title,
            summary: _ebookDetails.summary,
            assetFile: _ebookDetails.assetFile,
            assetSampleFile: _ebookDetails.assetSampleFile,
            coverImage: _ebookDetails.coverImage,
            isSendNotif: _ebookDetails.isSendNotif,
            isShowApp: _ebookDetails.isShowApp,
            aboutCompany: _ebookDetails.aboutCompany,
            aboutImage: _ebookDetails.aboutImage
        });
        ebooks[_appId] = ebookDetails;

        _updateGaslessData(gasLeftInit);
    }

  

    function getWelcomeMessage(bytes32 _appId) external view returns(string memory, string memory, string memory){

        if (ebooks[_appId].isSendNotif)
            return (ebookMessage[_appId].message, ebookMessage[_appId].cta, ebookMessage[_appId].buttonName);
        else             
            return (welcomeMessage[_appId].message, welcomeMessage[_appId].cta, welcomeMessage[_appId].buttonName);


    }

      function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }
}