// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
// import "./ERC2771ContextUpgradeable.sol";
// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./GasRestrictor.sol";

// import "./ERC2771ContextUpgradeable.sol";
import {UnifarmAccountsUpgradeable} from "./UnifarmAccountsUpgradeable.sol";

contract MessagingUpgradeable is Initializable, OwnableUpgradeable {

    bytes32 public dappId;     // dappID for this decentralized messaging application (should be fixed)
    UnifarmAccountsUpgradeable public unifarmAccounts;
    GasRestrictor public gasRestrictor;


    // ---------------- ATTACHMENTS STORAGE ---------------

    struct Attachment {
        string location;
        string fileType;
        address receiver;
        string rsaKeyReceiver;       // encrypted using receiver's public key
        string rsaKeySender;         // encrypted using sender's public key
        bool isEncrypted;
    }

    // dataID => attachment
    mapping(uint256 => Attachment) public attachments;

    uint256 public dataIdsCount;

    mapping(address => uint256[]) public receiverAttachments;   // to get all the files received by the user (gdrive analogy)

    // ------------------ MESSAGE STORAGE ------------------

    struct Message {
        address sender;
        string textMessageReceiver;      // encrypted using receiver's public key
        string textMessageSender;        // encrypted using sender's public key
        uint256[] attachmentIds;
        bool isEncrypted;                // to check if the message has been encrypted
        uint256 timestamp;
    }

    // from => to => messageID
    mapping(address => mapping(address => uint256)) public messageIds;

    // to keep a count of all the 1 to 1 communication
    uint256 public messageIdCount;

    // messageID => messages[]
    mapping(uint256 => Message[]) public messages;

    // ------------------ WHITELISTING STORAGE ------------------

    mapping(address => bool) public isWhitelisting;

    // from => to => isWhitelisted
    mapping(address => mapping(address => bool)) public isWhitelisted;

    // ------------------ SPAM RPOTECTION STORAGE ------------------

    mapping(address => bool) public isSpamProtecting;

    address public ufarmToken;
    address public spamTokensAdmin;

    // set by dappAdmin
    address[] public spamProtectionTokens;

    struct SpamProtectionToken {
        address token;
        uint256 amount;     // amount to pay in wei for message this user
    }

    // userAddress => tokens
    mapping(address => SpamProtectionToken[]) public userSpamTokens;

    struct TokenTransferMapping {
        address token;
        uint256 amount;
        uint256 startTimestamp;
    }

    // from => to => TokenTransferMapping
    mapping(address => mapping(address => TokenTransferMapping)) public tokenTransferMappings;

    event MessageSent(
        address indexed from,
        address indexed to,
        uint256 indexed messageId,
        string textMessageReceiver,
        string textMessageSender,
        uint256[] attachmentIds,
        bool isEncrypted,
        uint256 timestamp
    );

    event AddedToWhitelist(
        address indexed from,
        address indexed to
    );

    event RemovedFromWhitelist(
        address indexed from,
        address indexed to
    );

    modifier isValidSender(
        address _from
    ) {
        _isValidSender(_from);
        _;
    }

    function _isValidSender(
        address _from
    ) internal view {
        // _msgSender() should be either primary (_from) or secondary wallet of _from
        require(_msgSender() == _from || 
                _msgSender() == unifarmAccounts.getSecondaryWalletAccount(_from), "INVALID_SENDER");
    }

     modifier GasNotZero(address user) {
      
        if (unifarmAccounts.getPrimaryFromSecondary(user) == address(0)) {
             _;
        } else {
                address a;
                address b;
                uint u;
                (a, b ,u) = gasRestrictor.gaslessData(unifarmAccounts.getPrimaryFromSecondary(user));
            require(
                 u != 0,
                "NOT_ENOUGH_GASBALANCE"
            );
          _;
        }
    }

    function __Messaging_init(
        bytes32 _dappId,
        UnifarmAccountsUpgradeable _unifarmAccounts,
        // GasRestrictor _gasRestrictor,
        address _ufarmToken,
        address _spamTokensAdmin,
        address _trustedForwarder
    ) public initializer {
        __Ownable_init(_trustedForwarder);

        // __Pausable_init();
        // __ERC2771ContextUpgradeable_init(_trustedForwarder);
        // _trustedForwarder = trustedForwarder;
        dappId = _dappId;
        unifarmAccounts = _unifarmAccounts;
        ufarmToken = _ufarmToken;
        spamTokensAdmin = _spamTokensAdmin;
        // init_Gasless_Restrictor(address(_unifarmAccounts), 5 ether);

    }

    // ------------------ ATTACHMENT FUNCTIONS ----------------------

    function writeData(
        string memory _location,
        string memory _fileType,
        address _receiver,
        string memory _rsaKeyReceiver,
        string memory _rsaKeySender,
        bool _isEncrypted
    ) internal returns (uint256) {
        uint256 dataId = dataIdsCount++;
        Attachment memory attachment = Attachment({
            location: _location,
            fileType: _fileType,
            receiver: _receiver,
            rsaKeyReceiver: _rsaKeyReceiver,
            rsaKeySender: _rsaKeySender,
            isEncrypted: _isEncrypted
        });
        attachments[dataId] = attachment;
        receiverAttachments[_receiver].push(dataId);
        return dataId;
    }

    // -------------------- MESSAGE FUNCTIONS -----------------------

    // function to send message when receiver's spam protection is OFF
    function newMessage(
        address _from,
        address _to,
        string calldata _textMessageReceiver,
        string calldata _textMessageSender,
        Attachment[] calldata _attachments,
        bool _isEncrypted
    ) public isValidSender(_from) {
        uint gasLeftInit = gasleft();
        bool isSendWhitelisted = isWhitelisted[_from][_to];
        // bool isReceiveWhitelisted = isWhitelisted[_to][_msgSender()];

        // check if the receiver has whitelisting enabled and user is whitelisted by the receiver
        if(isWhitelisting[_to])
            require(isSendWhitelisted, "NOT_WHITELISTED");

        _createMessageRecord(_from, _to, _textMessageReceiver, _textMessageSender, _attachments, _isEncrypted);

          //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }

    // function to send message when receiver's spam protection is ON
    function newMessageOnSpamProtection(
        address _from,
        address _to,
        string calldata _textMessageReceiver,
        string calldata _textMessageSender,
        Attachment[] calldata _attachments,
        bool _isEncrypted,
        ERC20 _token
    ) public isValidSender(_from) {
        uint gasLeftInit = gasleft();

        bool isSendWhitelisted = isWhitelisted[_from][_to];

        // check if the receiver has whitelisting enabled and user is whitelisted by the receiver
        if(isWhitelisting[_to])
            require(isSendWhitelisted, "NOT_WHITELISTED");

        // check if receiver has spam protection enabled
        if(isSpamProtecting[_to] && !isSendWhitelisted) {
            _createSpamRecord(_from, _to, _token);
        }

        _createMessageRecord(_from, _to, _textMessageReceiver, _textMessageSender, _attachments, _isEncrypted);
            //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }

    function _createMessageRecord(
        address _from,
        address _to,
        string memory _textMessageReceiver,
        string memory _textMessageSender,
        Attachment[] memory _attachments,
        bool _isEncrypted
    ) internal {
        // to check if tokenTransferMappings record exists
        if(tokenTransferMappings[_to][_from].startTimestamp > 0) {
            TokenTransferMapping memory tokenTransferMapping = tokenTransferMappings[_to][_from];
            delete tokenTransferMappings[_to][_from];
            
            ERC20(tokenTransferMapping.token).transfer(_from, tokenTransferMapping.amount);
        }

        uint len = _attachments.length;
        uint[] memory attachmentIds = new uint[](len);
        for (uint i = 0; i < len; i++) {
            uint256 dataId = writeData(
                _attachments[i].location, 
                _attachments[i].fileType, 
                _attachments[i].receiver, 
                _attachments[i].rsaKeyReceiver, 
                _attachments[i].rsaKeySender, 
                _attachments[i].isEncrypted
            );
            attachmentIds[i] = dataId;
        }

        Message memory message = Message({
            sender: _from,
            textMessageReceiver: _textMessageReceiver,
            textMessageSender: _textMessageSender,
            isEncrypted: _isEncrypted,
            attachmentIds: attachmentIds,
            timestamp: block.timestamp
        });

        uint256 messageId = messageIds[_from][_to];
        if(messageId == 0) {
            messageId = ++messageIdCount;
            messageIds[_from][_to] = messageId;
            messageIds[_to][_from] = messageId;
            emit AddedToWhitelist(_from, _to);
            emit AddedToWhitelist(_to, _from);
        }
        messages[messageId].push(message);
        
        emit MessageSent(_from, _to, messageId, _textMessageReceiver, _textMessageSender, attachmentIds, _isEncrypted, block.timestamp);
    } 

    function _createSpamRecord(
        address _from,
        address _to,
        ERC20 _token
    ) internal {
        uint256 amount = getTokenAmountToSend(_from, address(_token));
        require(amount > 0, "INVALID_TOKEN");
        uint256 adminAmount;
        if(address(_token) != ufarmToken) {
            adminAmount = amount / 5;   // 20% goes to admin
            amount -= adminAmount;
            _token.transferFrom(_from, spamTokensAdmin, adminAmount);
        }
        _token.transferFrom(_from, address(this), amount);
        tokenTransferMappings[_from][_to] = TokenTransferMapping({
            token: address(_token),
            amount: amount,
            startTimestamp: block.timestamp
        });

        isWhitelisted[_from][_to] = true;
        emit AddedToWhitelist(_from, _to);
        
        isWhitelisted[_to][_from] = true;
        emit AddedToWhitelist(_to, _from);
    }

    function getTokenAmountToSend(
        address _account,
        address _token
    ) public view returns (uint256) {
        SpamProtectionToken[] memory spamTokens = userSpamTokens[_account];
        for (uint256 i = 0; i < spamTokens.length; i++) {
            if(spamTokens[i].token == _token)
                return spamTokens[i].amount;
        }
        return 0;
    }

    // function getMessageForReceiver(
    //     address receiver,
    //     uint256 limit, 
    //     uint256 offset
    // ) public view returns (Message[] memory) {
    //     uint startIndex = limit * offset;
    //     uint endIndex = startIndex + limit;
    //     uint len = userReceivedMessages[receiver].length;
    //     Message[] memory receivedMessages = new Message[](len);
    //     for (uint i = startIndex; i < endIndex && i < len; i++) {
    //         receivedMessages[i] = userReceivedMessages[receiver][i];
    //     }
    //     return receivedMessages;
    // }

    // function getMessageForSender(
    //     address sender,
    //     uint256 limit, 
    //     uint256 offset
    // ) public view returns (Message[] memory) {
    //     uint startIndex = limit * offset;
    //     uint endIndex = startIndex + limit;
    //     uint len = userSentMessages[sender].length;
    //     Message[] memory sentMessages = new Message[](len);
    //     for (uint i = startIndex; i < endIndex && i < len; i++) {
    //         sentMessages[i] = userSentMessages[sender][i];
    //     }
    //     return sentMessages;
    // }

    function getCommunication(
        address _from,
        address _to
    ) public view returns (Message[] memory) {
        uint256 messageId = messageIds[_from][_to];
        return messages[messageId];
    }

    // ------------------ SPAM RPOTECTION FUNCTIONS ------------------

    function adminAddPaymentToken(
        address _token
    ) external {
        uint gasLeftInit = gasleft();
        require(_msgSender() == unifarmAccounts.getDappAdmin(dappId), "ONLY_DAPP_ADMIN");
        require(_token != address(0), "INVALID_ADDRESS");

        uint len = spamProtectionTokens.length;
        for(uint256 i = 0; i < len; i++) {
            require(spamProtectionTokens[i] != _token, "TOKEN_ALREADY_EXISTS");
        }
        spamProtectionTokens.push(_token);

        //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }

    function adminRemovePaymentToken(
        address _token
    ) external {
        require(_msgSender() == unifarmAccounts.getDappAdmin(dappId), "ONLY_DAPP_ADMIN");
        require(_token != address(0), "INVALID_ADDRESS");
        
        uint len = spamProtectionTokens.length;
        for(uint256 i = 0; i < len; i++) {
            if(spamProtectionTokens[i] == _token) {
                if(i < len-1) {
                    spamProtectionTokens[i] = spamProtectionTokens[len-1];
                }
                spamProtectionTokens.pop();
                return;
            }
        }
        revert("NO_TOKEN");


    }

    // to add a new token or update the price of alreayd added token
    function addSpamProtectionToken(
        address _account,
        address _token,
        uint256 _amount
    ) external isValidSender(_account) {
        uint gasLeftInit = gasleft();
        require(_token != address(0), "INVALID_ADDRESS");
        require(_amount > 0, "ZERO_AMOUNT");

        uint len = spamProtectionTokens.length;
        uint8 count;
        for(uint256 i = 0; i < len; i++) {
            // token should be allowed by the admin
            if(spamProtectionTokens[i] == _token) {
                count = 1;
                break;
            }
        }
        require(count == 1, "INVALID_TOKEN");
        
        len = userSpamTokens[_account].length;
        for(uint256 i = 0; i < len; i++) {
            // if token already exists then update its price and return
            if(userSpamTokens[_account][i].token == _token) {
                userSpamTokens[_account][i].amount = _amount;
                return;
            }
        }

        // If token doesn't exist then add it
        SpamProtectionToken memory token = SpamProtectionToken({
            token: _token,
            amount: _amount
        });
        userSpamTokens[_account].push(token);


           //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }
    
    function removeSpamProtectionToken(
        address _account,
        address _token
    ) external isValidSender(_account) {
        require(_token != address(0), "INVALID_ADDRESS");
        
        uint len = userSpamTokens[_account].length;
        for(uint256 i = 0; i < len; i++) {
            if(userSpamTokens[_account][i].token == _token) {
                if(i < len-1) {
                    userSpamTokens[_account][i] = userSpamTokens[_account][len-1];
                }
                userSpamTokens[_account].pop();
                return;
            }
        }
        revert("NO_TOKEN");
    }

    function setIsSpamProtecting(
        address _account,
        bool _isSpamProtecting
    ) external isValidSender(_account) {
        uint gasLeftInit = gasleft();

        isSpamProtecting[_account] = _isSpamProtecting;

           //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }

    function getRefund(
        address _user,
        address _to
    ) external isValidSender(_user) {
        uint gasLeftInit = gasleft();
        // tokenTransferMappings record should exist
        require(tokenTransferMappings[_user][_to].startTimestamp > 0, "NO_RECORD");
        // 7 days time must have passed
        require(block.timestamp > tokenTransferMappings[_user][_to].startTimestamp + 7 days, "TIME_PENDING");
        
        TokenTransferMapping memory tokenTransferMapping = tokenTransferMappings[_user][_to];
        delete tokenTransferMappings[_user][_to];
        ERC20(tokenTransferMapping.token).transfer(_user, tokenTransferMapping.amount);

           //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }

    // ------------------ WHITELISTING FUNCTIONS ------------------

    function setIsWhitelisting(
        address _account,
        bool _isWhitelisting
    ) external isValidSender(_account) {
        isWhitelisting[_account] = _isWhitelisting;
    }

    function addWhitelist(
        address _user,
        address _account
    ) external isValidSender(_user) {
        uint gasLeftInit = gasleft();
        isWhitelisted[_account][_user] = true;
        emit AddedToWhitelist(_account, _user);

           //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }

    function removeWhitelist(
        address _user,
        address _account
    ) external isValidSender(_user) {
        uint gasLeftInit = gasleft();

        isWhitelisted[_account][_user] = false;
        emit RemovedFromWhitelist(_account, _user);

           //  if(msg.sender == trustedForwarder) {
         gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
    //    }
    }

}