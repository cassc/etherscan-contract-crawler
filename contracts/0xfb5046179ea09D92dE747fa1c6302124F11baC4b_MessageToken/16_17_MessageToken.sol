//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {ERC721Enumerable, ERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageValidator} from "./interface/IMessageValidator.sol";


contract MessageToken is ERC721Enumerable, AccessControl, Ownable, IERC2981 {

    // ============ROLE PERMISSIONS=============
    bytes32 public constant MESSAGE_UPDATER_ADMIN = keccak256("MESSAGE_UPDATER_ADMIN");
    bytes32 public constant MESSAGE_VALIDATOR_UPDATER_ADMIN = keccak256("MESSAGE_VALIDATOR_UPDATER_ADMIN");
    bytes32 public constant TOKENURI_UPDATER_ADMIN = keccak256("TOKENURI_UPDATER_ADMIN");
    bytes32 public constant EXTRA_TEXT_UPDATER_ADMIN = keccak256("EXTRA_TEXT_UPDATER_ADMIN");

    bytes32 public constant MESSAGE_UPDATER_ROLE = keccak256("MESSAGE_UPDATER_ROLE");
    bytes32 public constant MESSAGE_VALIDATOR_UPDATER_ROLE = keccak256("MESSAGE_VALIDATOR_UPDATER_ROLE");
    bytes32 public constant TOKENURI_UPDATER_ROLE = keccak256("TOKENURI_UPDATER_ROLE");
    bytes32 public constant EXTRA_TEXT_UPDATER_ROLE = keccak256("EXTRA_TEXT_UPDATER_ROLE");

    // ======= PUBLIC STATE VARIABLES ==========
    uint256 public constant MAX_TOTAL_SUPPLY = 7;
    string public constant TITLE = "MATTER IS VOID";
    string public constant SYMBOL = "VOID";
    address public royaltyReceiver;
    uint256 public royaltyPercentBips;


    // tokenId -> message
    mapping(uint256 => string) public messages;
    // whether a message has ever been edited by its owner
    mapping(uint256 => bool) public isEdited;

    // tokenId -> tokenURI
    mapping(uint256 => string) public tokenURIs;

    // optional extra text for some tokens
    mapping(uint256 => string) public extraText;

    // tokenId -> address of `IMessageValidator`
    // @dev if validators[i] is 0x0, all strings are valid for token `i`
    mapping(uint256 => address) public validators;


    // ====================================

    // ============= EVENTS ================
    event MessageUpdated(uint256 indexed  tokenId, string message);
    event MessageUpdatedByOperator(uint256 indexed tokenId, string message);
    event TokenURIUpdated(uint256 indexed tokenId, string latest);
    event ValidatorUpdated(uint256 indexed tokenId, address indexed validator);
    event ExtraTextUpdated(uint256 indexed tokenId, string extraText);

    // ============ MODIFIERS ===============
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(_msgSender() == ownerOf(_tokenId), "not owner");
        // ownerOf also ensures token exists
        _;
    }

    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "token does not exist");
        _;
    }

    // @dev if token `i` has no validator, all messages are valid for `i`
    modifier onlyValidMessageForToken(uint256 _tokenId, string memory _message) {
        address validator = validators[_tokenId];
        if (validator != address(0)) {
            // this token has a validator
            IMessageValidator.Result memory res = IMessageValidator(validator).validate(_message);
            require(
                res.isValid,
                res.message
            );
        }
        _;
    }

    constructor(
        address _teamLabMultisig,
        address _receivingWallet,
        address _royaltyReceiver,
        address _messageValidator,
        string[] memory _initialTokenURIs,
        string[] memory _extraText
    ) ERC721(TITLE, SYMBOL) {
        royaltyReceiver = _royaltyReceiver;
        royaltyPercentBips = 1000; // 10%

        // set role administration: each ADMIN role administrates itself
        // and a subordinate feature role. There is no SUPERADMIN so individual
        // features can be permanently abandoned when all authorized users
        // renounce it.
        _setRoleAdmin(MESSAGE_UPDATER_ADMIN, MESSAGE_UPDATER_ADMIN);
        _setRoleAdmin(MESSAGE_UPDATER_ROLE, MESSAGE_UPDATER_ADMIN);

        _setRoleAdmin(MESSAGE_VALIDATOR_UPDATER_ADMIN, MESSAGE_VALIDATOR_UPDATER_ADMIN);
        _setRoleAdmin(MESSAGE_VALIDATOR_UPDATER_ROLE, MESSAGE_VALIDATOR_UPDATER_ADMIN);

        _setRoleAdmin(TOKENURI_UPDATER_ADMIN, TOKENURI_UPDATER_ADMIN);
        _setRoleAdmin(TOKENURI_UPDATER_ROLE, TOKENURI_UPDATER_ADMIN);

        _setRoleAdmin(EXTRA_TEXT_UPDATER_ADMIN, EXTRA_TEXT_UPDATER_ADMIN);
        _setRoleAdmin(EXTRA_TEXT_UPDATER_ROLE, EXTRA_TEXT_UPDATER_ADMIN);

        // set teamLab as initial admin for roles
        _grantRole(MESSAGE_UPDATER_ADMIN, _teamLabMultisig);
        _grantRole(MESSAGE_VALIDATOR_UPDATER_ADMIN, _teamLabMultisig);
        _grantRole(TOKENURI_UPDATER_ADMIN, _teamLabMultisig);

        _grantRole(MESSAGE_UPDATER_ROLE, _teamLabMultisig);
        _grantRole(MESSAGE_VALIDATOR_UPDATER_ROLE, _teamLabMultisig);
        _grantRole(TOKENURI_UPDATER_ROLE, _teamLabMultisig);

        // give the initial recipient ability to modify extraTexts
        _grantRole(EXTRA_TEXT_UPDATER_ADMIN, _receivingWallet);
        _grantRole(EXTRA_TEXT_UPDATER_ROLE, _receivingWallet);

        require(
            _initialTokenURIs.length == MAX_TOTAL_SUPPLY,
            "tokenURI length"
        );
        // mint all tokens to initial holding wallet
        for (uint256 i = 0; i < MAX_TOTAL_SUPPLY; ++i) {
            messages[i] = "MATTER\nIS\nVOID";
            validators[i] = _messageValidator;
            tokenURIs[i] = _initialTokenURIs[i];
            _mint(_receivingWallet, i);
        }
        for (uint256 i = 0; i < _extraText.length; ++i) {
            extraText[i] = _extraText[i];
        }
    }

    // ====== TOKEN OWNER METHODS ======

    // @dev throws if owner, token, or message are invalid
    function setMessage(uint256 _tokenId, string calldata _message) external
        // the token is valid
        onlyValidTokenId(_tokenId)
        // the owner is valid,
        onlyTokenOwner(_tokenId)
        // .. and the message is valid
        onlyValidMessageForToken(_tokenId, _message)
    {
        messages[_tokenId] = _message;
        isEdited[_tokenId] = true;
        emit MessageUpdated(_tokenId, _message);
    }

    // ====== TEAMLAB ADMIN OPTIONS ======

    // admin option for teamLab in case of malicious or errors
    function setMessageByOperator(uint256 _tokenId, string calldata _message) external
        onlyRole(MESSAGE_UPDATER_ROLE)
        onlyValidTokenId(_tokenId)
        // still validate message to ensure clean
        onlyValidMessageForToken(_tokenId, _message)
    {
        messages[_tokenId] = _message;
        emit MessageUpdatedByOperator(_tokenId, _message);
    }

    function setValidator(uint256 _tokenId, address _validator) external
        onlyRole(MESSAGE_VALIDATOR_UPDATER_ROLE)
        onlyValidTokenId(_tokenId)
    {
        validators[_tokenId] = _validator;
        emit ValidatorUpdated(_tokenId, _validator);
    }

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external
        onlyRole(TOKENURI_UPDATER_ROLE)
        onlyValidTokenId(_tokenId)
    {
        tokenURIs[_tokenId] = _tokenURI;
        emit TokenURIUpdated(_tokenId, _tokenURI);
    }

    function setExtraText(uint256 _tokenId, string calldata _extraText) external
        onlyRole(EXTRA_TEXT_UPDATER_ROLE)
        onlyValidTokenId(_tokenId)
    {
        extraText[_tokenId] = _extraText;
        emit ExtraTextUpdated(_tokenId, _extraText);
    }

    // ====== PUBLIC VIEW MESSAGES ======

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return tokenURIs[_tokenId];
    }

    function royaltyInfo(uint256 /*tokenId*/, uint256 _salePrice) external view virtual override 
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceiver;
        royaltyAmount = (_salePrice * royaltyPercentBips) / 10000; // 10,000 is 100% in bips
    }

    // @dev because ERC721 and AccessControl both implement this function,
    // solidity makes us override it and specify the inheritance order (eg specify `super`)
    function supportsInterface(bytes4 interfaceId) public view virtual override(
        AccessControl,
        ERC721Enumerable,
        IERC165
    ) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}