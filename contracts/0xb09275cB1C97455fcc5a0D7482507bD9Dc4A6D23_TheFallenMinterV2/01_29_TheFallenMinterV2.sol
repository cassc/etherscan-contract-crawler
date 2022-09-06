// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./libraries/OperatorAccess.sol";
import "./libraries/AuthorizeAccess.sol";
import "./TheFallen.sol";
import "./interfaces/IStaking.sol";

/**
 * @title TheFallen MinterV2
 * @notice TheFallen Minting Station V2
 */
contract TheFallenMinterV2 is AuthorizeAccess, OperatorAccess, ReentrancyGuard, EIP712 {
    struct RoundConfiguration {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 maxMint;
        bool requiresSignature;
    }

    bytes32 public constant SIGN_MINT_TYPEHASH = keccak256("Mint(uint256 quantity,uint8 round,address account)");

    TheFallen public immutable nftCollection;
    address public immutable vault;

    uint8 public roundId;
    mapping(uint8 => RoundConfiguration) private _roundConfigurations;
    mapping(address => mapping(uint8 => uint256)) private _userMints;
    uint256 private _currentIdx;
    uint256[] private _tokenIds;

    modifier whenMintOpened() {
        require(_roundConfigurations[roundId].startTimestamp > 0, "Round not configured");
        require(_roundConfigurations[roundId].startTimestamp <= block.timestamp, "Round not opened");
        require(
            _roundConfigurations[roundId].endTimestamp == 0 ||
                _roundConfigurations[roundId].endTimestamp >= block.timestamp,
            "Round closed"
        );
        _;
    }

    modifier whenValidQuantity(uint256 quantity) {
        require(quantity > 0, "Qty <= 0");
        require(_tokenIds.length > 0, "No more supply");
        require(_tokenIds.length >= quantity, "Not enough supply");
        _;
    }

    modifier whenMaxPerUserNotReached(address account, uint256 quantity) {
        require(
            _userMints[account][roundId] + quantity <= _roundConfigurations[roundId].maxMint,
            "Max user mint reached"
        );
        _;
    }

    // modifier to allow execution by owner or operator
    modifier onlyOwnerOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()),
            "Not an owner or operator"
        );
        _;
    }

    constructor(TheFallen collection_, address vault_) EIP712("The Fallen", "1.0") {
        nftCollection = collection_;
        vault = vault_ == address(0) ? address(this) : vault_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _hashMintPayload(
        uint256 _quantity,
        uint8 _round,
        address _account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SIGN_MINT_TYPEHASH, _quantity, _round, _account));
    }

    /**
     * @notice verifify signature is valid for `structHash` and signers is a member of role `AUTHORIZER_ROLE`
     * @param structHash: hash of the structure to verify the signature against
     */
    function isAuthorized(bytes32 structHash, bytes memory signature) internal view returns (bool) {
        bytes32 hash = _hashTypedDataV4(structHash);
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && hasRole(AUTHORIZER_ROLE, recovered)) {
            return true;
        }

        return false;
    }

    function setRoundId(uint8 roundId_) external onlyOwnerOrOperator {
        roundId = roundId_;
    }

    /**
     * @dev configure the round
     */
    function configureRound(uint8 roundId_, RoundConfiguration calldata configuration_) external onlyOwnerOrOperator {
        require(
            configuration_.endTimestamp == 0 || configuration_.startTimestamp < configuration_.endTimestamp,
            "Invalid timestamps"
        );
        _roundConfigurations[roundId_] = configuration_;
    }

    function getRoundConfiguration(uint8 roundId_) public view returns (RoundConfiguration memory) {
        return _roundConfigurations[roundId_];
    }

    function preMint(
        uint256[] calldata tokenIds_,
        uint256[] calldata linkedSamuraiIds_,
        uint256[] calldata linkedOnnaIds_
    ) external onlyOwnerOrOperator {
        nftCollection.mintBatch(vault, tokenIds_, linkedSamuraiIds_, linkedOnnaIds_);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _tokenIds.push(tokenIds_[i]);
        }
    }

    function _mint(address to, uint256 quantity) private {
        _userMints[to][roundId] += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            nftCollection.safeTransferFrom(vault, to, _tokenIds[_currentIdx + i]);
        }
        _currentIdx += quantity;
    }

    function mint(uint256 quantity)
        external
        nonReentrant
        whenValidQuantity(quantity)
        whenMaxPerUserNotReached(msg.sender, quantity)
        whenMintOpened
    {
        require(!_roundConfigurations[roundId].requiresSignature, "Round requires signature");
        _mint(msg.sender, quantity);
    }

    function mintSigned(uint256 quantity, bytes memory signature)
        external
        nonReentrant
        whenValidQuantity(quantity)
        whenMaxPerUserNotReached(msg.sender, quantity)
        whenMintOpened
    {
        require(isAuthorized(_hashMintPayload(quantity, roundId, msg.sender), signature), "Not signed by authorizer");
        _mint(msg.sender, quantity);
    }

    function getUserMints(address account_, uint8 roundId_) public view returns (uint256) {
        return _userMints[account_][roundId_];
    }
}