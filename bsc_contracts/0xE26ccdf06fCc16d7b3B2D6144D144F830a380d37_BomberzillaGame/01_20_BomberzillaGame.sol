//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Rescueable.sol";

contract BomberzillaGame is AccessControl, ERC721Holder, ERC1155Holder, Rescueable {
    using SafeERC20 for IERC20;

    enum TokenStandard {
        ERC20,
        ERC721,
        ERC1155
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TokenClaimData {
        address token;
        uint256 nonce;
        uint256 amount;
        uint256 tokenId;
        uint256 deadline;
        Signature[] signatures;
        uint256 signatureTimestamp;
        TokenStandard tokenStandard;
    }

    struct TokenDepositData {
        address token;
        uint256 amount;
        uint256 tokenId;
        TokenStandard tokenStandard;
    }

    bytes32 public constant CLAIM_SIGNER_ROLE = keccak256("CLAIM_SIGNER_ROLE");
    bytes32 public constant TOKENCLAIM_TYPEHASH =
        keccak256(
            "TokenClaim(address user,uint256 nonce,uint8 tokenStandard,uint256 tokenId,uint256 amount,uint256 signatureTimestamp,uint256 deadline)"
        );
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant EMERGENCY_LOCK_ROLE = keccak256("EMERGENCY_LOCK_ROLE");

    bool public emergencyLock;
    uint256 public minValidSignersCount;
    uint256 public claimDelay;
    uint256 public maxClaim;

    mapping(address => bool) public blacklist;
    mapping(address => mapping(uint256 => bool)) public claimed; // user address => nonce => claimed or not
    mapping(address => mapping(uint256 => bool)) public cancelled; // user address => nonce => cancelled or not

    event MaxClaimUpdated(uint256 amount);
    event ClaimDelayUpdated(uint256 value);
    event EmergencyLockUpdated(bool status);
    event MinValidSignatureCountUpdated(uint256 count);
    event BlacklistUpdated(address indexed account, bool status);
    event BatchClaimed(address indexed account, uint256[] indexed nonces);
    event NonceCancelled(address indexed account, uint256 indexed nonce);
    event NonceCancelledBatch(address indexed account, uint256[] indexed nonces);
    event BatchDeposited(address indexed account, TokenDepositData[] depositData);
    event TokenDeposited(
        address indexed token,
        address indexed account,
        uint8 tokenStandard,
        uint256 tokenId,
        uint256 amount
    );
    event TokenClaimed(
        address indexed token,
        address indexed account,
        uint256 indexed nonce,
        uint8 tokenStandard,
        uint256 tokenId,
        uint256 amount
    );

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "BomberzillaGame: blacklisted sender");
        _;
    }

    constructor(uint256 _claimDelay, uint256 _minSigner, uint256 _maxClaim) {
        updateClaimDelay(_claimDelay);
        updateMaxClaim(_maxClaim);
        updateMinValidSignatureCount(_minSigner);
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("BomzerbillaGame")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CLAIM_SIGNER_ROLE, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return
            ERC1155Receiver.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function cancelNonce(uint256 nonce) public notBlacklisted {
        require(!claimed[msg.sender][nonce], "BomberzillaGame: Nonce already claimed");
        cancelled[msg.sender][nonce] = true;
        emit NonceCancelled(msg.sender, nonce);
    }

    function cancelNonceBatch(uint256[] calldata nonces) public notBlacklisted {
        for (uint256 i = 0; i < nonces.length; i++) {
            cancelNonce(nonces[i]);
        }

        emit NonceCancelledBatch(msg.sender, nonces);
    }

    function batchClaim(TokenClaimData[] calldata _claimData) public notBlacklisted {
        uint256[] memory nonces = new uint256[](_claimData.length);

        for (uint256 i = 0; i < _claimData.length; i++) {
            nonces[i] = _claimData[i].nonce;
            claim(_claimData[i]);
        }

        emit BatchClaimed(msg.sender, nonces);
    }

    function claim(TokenClaimData calldata _claimData) public notBlacklisted {
        require(!emergencyLock, "BomberzillaGame: Contract is locked");
        require(_claimData.signatureTimestamp + claimDelay <= block.timestamp, "BomberzillaGame: Claim too soon!");
        require(_claimData.deadline >= block.timestamp, "BomberzillaGame: Claim expired");
        require(!cancelled[msg.sender][_claimData.nonce], "BomberzillaGame: Nonce cancelled");
        require(!claimed[msg.sender][_claimData.nonce], "BomberzillaGame: Nonce claimed");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        TOKENCLAIM_TYPEHASH,
                        msg.sender,
                        _claimData.nonce,
                        _claimData.tokenStandard,
                        _claimData.tokenId,
                        _claimData.amount,
                        _claimData.signatureTimestamp,
                        _claimData.deadline
                    )
                )
            )
        );

        validateSignatures(digest, _claimData.signatures);

        if (TokenStandard(_claimData.tokenStandard) == TokenStandard.ERC20) {
            require(maxClaim >= _claimData.amount, "BomberzillaGame: claim amount too high!");
            IERC20 token = IERC20(_claimData.token);
            token.safeTransfer(msg.sender, _claimData.amount);
        } else if (TokenStandard(_claimData.tokenStandard) == TokenStandard.ERC721) {
            IERC721 token = IERC721(_claimData.token);
            token.safeTransferFrom(address(this), msg.sender, _claimData.tokenId);
        } else if (TokenStandard(_claimData.tokenStandard) == TokenStandard.ERC1155) {
            IERC1155 token = IERC1155(_claimData.token);
            token.safeTransferFrom(address(this), msg.sender, _claimData.tokenId, _claimData.amount, "");
        }

        claimed[msg.sender][_claimData.nonce] = true;
        emit TokenClaimed(
            _claimData.token,
            msg.sender,
            _claimData.nonce,
            uint8(_claimData.tokenStandard),
            _claimData.tokenId,
            _claimData.amount
        );
    }

    function validateSignatures(bytes32 digest, Signature[] calldata _signature) private view {
        uint256 validSignerCount = 0;
        address[] memory signers = new address[](_signature.length);

        for (uint256 x = 0; x < _signature.length; x++) {
            address signer = ecrecover(digest, _signature[x].v, _signature[x].r, _signature[x].s);

            if (hasRole(CLAIM_SIGNER_ROLE, signer)) {
                for (uint256 y = 0; y < validSignerCount; y++) {
                    require(signers[y] != signer, "BomberzillaGame: Duplicate signature");
                }
                signers[validSignerCount++] = signer;
            }
        }
        require(validSignerCount != 0, "BomberzillaGame: Invalid Signatures");
        require(minValidSignersCount <= validSignerCount, "BomberzillaGame: Not enough valid signatures");
    }

    function batchDeposit(TokenDepositData[] calldata _depositData) public notBlacklisted {
        for (uint256 i = 0; i < _depositData.length; i++) {
            deposit(_depositData[i]);
        }

        emit BatchDeposited(msg.sender, _depositData);
    }

    function deposit(TokenDepositData calldata _depositData) public notBlacklisted {
        if (TokenStandard(_depositData.tokenStandard) == TokenStandard.ERC20) {
            IERC20 token = IERC20(_depositData.token);
            token.safeTransferFrom(msg.sender, address(this), _depositData.amount);
        } else if (TokenStandard(_depositData.tokenStandard) == TokenStandard.ERC721) {
            IERC721 token = IERC721(_depositData.token);
            token.safeTransferFrom(msg.sender, address(this), _depositData.tokenId);
        } else if (TokenStandard(_depositData.tokenStandard) == TokenStandard.ERC1155) {
            IERC1155 token = IERC1155(_depositData.token);
            token.safeTransferFrom(msg.sender, address(this), _depositData.tokenId, _depositData.amount, "");
        }

        emit TokenDeposited(
            _depositData.token,
            msg.sender,
            uint8(_depositData.tokenStandard),
            _depositData.tokenId,
            _depositData.amount
        );
    }

    function grantRoleBatch(bytes32 role, address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            grantRole(role, users[i]);
        }
    }

    function revokeRoleBatch(bytes32 role, address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            revokeRole(role, users[i]);
        }
    }

    function updateMinValidSignatureCount(uint256 count) public onlyOwner {
        minValidSignersCount = count;
        emit MinValidSignatureCountUpdated(count);
    }

    function updateEmergencyLock(bool status) external {
        require(
            hasRole(EMERGENCY_LOCK_ROLE, msg.sender) || msg.sender == owner(),
            "BomberzillaGame: You don't have EMERGENCY_LOCK_ROLE"
        );
        emergencyLock = status;
        emit EmergencyLockUpdated(status);
    }

    function updateBlacklist(address account, bool status) external onlyOwner {
        blacklist[account] = status;
        emit BlacklistUpdated(account, status);
    }

    function updateClaimDelay(uint256 _delay) public onlyOwner {
        claimDelay = _delay;
        emit ClaimDelayUpdated(_delay);
    }

    function updateMaxClaim(uint256 _amount) public onlyOwner {
        maxClaim = _amount;
        emit MaxClaimUpdated(_amount);
    }
}