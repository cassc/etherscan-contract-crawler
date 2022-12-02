// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./MergeHelper.sol";
import "./Whitelist.sol";
import "./Error.sol";

contract MergeWorker is Initializable, ReentrancyGuardUpgradeable {
    IERC721 public dnft;
    address public adminContract;

    mapping(uint256 => bool) public isLocked;
    mapping(string => uint256) public mergeSetCreatedAt;
    mapping(string => bool) public isMergeSessionIdExist;
    mapping(string => mapping(string => bool)) public isTokenIdExistInMergeSession;

    uint256 private constant FOUR_MINUTES = 4 minutes;
    uint256 private constant ONE_MONTH = 30 days;

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        adminContract = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender != adminContract) revert UN_AUTHORIZED();
        _;
    }

    function setDnftAddress(IERC721 _dnftAddress) external onlyAdmin {
        if (address(_dnftAddress) == address(0)) revert ZERO_ADDRESS();
        adminContract = address(_dnftAddress);
        dnft = _dnftAddress;
    }

    function lockToken(uint256 _tokenId) private {
        isLocked[_tokenId] = true;
    }

    function unlockToken(uint256 _tokenId) private {
        isLocked[_tokenId] = false;
    }

    function isTokenLocked(uint256 _tokenId) external view returns (bool) {
        return isLocked[_tokenId];
    }

    function temporaryMerge(
        uint256 _nonces,
        address _sender,
        address _signer,
        uint256[] memory _tokenIds,
        uint256 _timestamp,
        string memory _sessionId,
        bytes memory _signature
    ) external nonReentrant onlyAdmin {
        if (_timestamp > block.timestamp || block.timestamp - _timestamp >= FOUR_MINUTES) revert INVALID_TIMESTAMP();
        if (!verifyMergeSignature(_nonces, _signer, _tokenIds, _timestamp, _sessionId, _signature))
            revert INVALID_SIGNATURE();
        if (isMergeSessionIdExist[_sessionId]) revert SESSION_ID_IS_USED();

        uint256 totalTokens = _tokenIds.length;
        for (uint256 i = 0; i < totalTokens; i++) {
            if (dnft.ownerOf(_tokenIds[i]) != _sender) revert NOT_OWNER_OF_TOKEN();
            if (isLocked[_tokenIds[i]]) revert TOKEN_IS_LOCKED();
            lockToken(_tokenIds[i]);
        }
        string memory mergeSet = MergeHelper.generateMergeSet(_tokenIds);
        mergeSetCreatedAt[mergeSet] = block.timestamp;
        isMergeSessionIdExist[_sessionId] = true;
        isTokenIdExistInMergeSession[_sessionId][mergeSet] = true;
    }

    function cancelTemporaryMerge(
        uint256 _nonces,
        address _sender,
        address _signer,
        uint256[] memory _tokenIds,
        uint256 _timestamp,
        string memory _sessionId,
        bytes memory _signature
    ) external nonReentrant onlyAdmin {
        if (!verifyMergeSignature(_nonces, _signer, _tokenIds, _timestamp, _sessionId, _signature))
            revert INVALID_SIGNATURE();
        string memory mergeSet = MergeHelper.generateMergeSet(_tokenIds);
        if (!isMergeSessionIdExist[_sessionId]) revert INVALID_SESSION_ID();
        if (mergeSetCreatedAt[mergeSet] == 0) revert MERGE_SET_NOT_FOUND();
        if (block.timestamp >= mergeSetCreatedAt[mergeSet] + ONE_MONTH) revert CANNOT_CANCEL_TEMP_MERGE();

        uint256 totalTokens = _tokenIds.length;
        for (uint256 i = 0; i < totalTokens; i++) {
            if (dnft.ownerOf(_tokenIds[i]) != _sender) revert NOT_OWNER_OF_TOKEN();
            if (!isLocked[_tokenIds[i]]) revert TOKEN_IS_NOT_LOCKED();
            unlockToken(_tokenIds[i]);
        }
        mergeSetCreatedAt[mergeSet] = 0;
        isMergeSessionIdExist[_sessionId] = false;
        isTokenIdExistInMergeSession[_sessionId][mergeSet] = false;
    }

    function executeTemporaryMerge(
        uint256[] memory _tokenIds,
        address _sender,
        string memory _sessionId
    ) external nonReentrant onlyAdmin returns (bool) {
        if (!isMergeSessionIdExist[_sessionId]) revert SESSION_ID_NOT_FOUND();
        string memory mergeSet = MergeHelper.generateMergeSet(_tokenIds);
        if (mergeSetCreatedAt[mergeSet] == 0) revert MERGE_SET_NOT_FOUND();
        if (block.timestamp < mergeSetCreatedAt[mergeSet] + ONE_MONTH) revert CANNOT_EXECUTE_TEMP_MERGE();
        if (!isTokenIdExistInMergeSession[_sessionId][mergeSet]) revert INVALID_TOKEN_IDS_OR_SESSION_ID();

        uint256 totalTokens = _tokenIds.length;
        for (uint256 i = 0; i < totalTokens; i++) {
            if (dnft.ownerOf(_tokenIds[i]) != _sender) return false;
            if (!isLocked[_tokenIds[i]]) return false;
        }
        mergeSetCreatedAt[mergeSet] = 0;
        return true;
    }

    function permanentMerge(
        uint256 _nonces,
        address _sender,
        address _signer,
        uint256[] memory _tokenIds,
        uint256 _timestamp,
        string memory _sessionId,
        bytes memory _signature
    ) external nonReentrant onlyAdmin returns (bool) {
        if (_timestamp > block.timestamp || block.timestamp - _timestamp >= FOUR_MINUTES) revert INVALID_TIMESTAMP();
        if (isMergeSessionIdExist[_sessionId]) revert SESSION_ID_IS_USED();
        if (!verifyMergeSignature(_nonces, _signer, _tokenIds, _timestamp, _sessionId, _signature))
            revert INVALID_SIGNATURE();

        uint256 totalTokens = _tokenIds.length;
        for (uint256 i = 0; i < totalTokens; i++) {
            if (dnft.ownerOf(_tokenIds[i]) != _sender) return false;
            if (isLocked[_tokenIds[i]]) return false;
        }

        isMergeSessionIdExist[_sessionId] = true;
        return true;
    }

    function verifyMergeSignature(
        uint256 _nonces,
        address _signer,
        uint256[] memory _tokenIds,
        uint256 _timestamp,
        string memory _sessionId,
        bytes memory _signature
    ) private pure returns (bool) {
        bytes memory bytesToVerify = abi.encode(_tokenIds, _timestamp, _sessionId);
        return (Whitelist.verifySignatureWhenMergeDNFT(_nonces, _signer, bytesToVerify, _signature));
    }
}