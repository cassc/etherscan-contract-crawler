// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "solmate/tokens/ERC721.sol";

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/interfaces/IERC721.sol";

import "./SignatureValidator.sol";
import "./MetadataComposer.sol";

error InvalidTokenId();
error RequiresTokenOwner();
error OwnerMetadataFunctionLocked();
error IncorrectMetadataNonce();
error InvalidMigrationCaller();
error TokenAlreadyMigrated();

contract AppliedPrimateEngineering is ERC721, SignatureValidator, Ownable {
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant OG_MAX = 222;

    bytes32 public constant OG_KEY = keccak256("OG");
    bytes32 public constant ONBOARDING_KEY = keccak256("ONBOARDING");

    mapping(uint256 => bytes32[]) private tokenMetadataKeys;
    mapping(uint256 => bytes32) private imageKeys;

    address private metadataStore;
    bool public ownerMetadataFunctionLocked;

    IERC721 private migration;

    constructor(address metadataStore_, address signer_, address migration_)
        ERC721("Applied Primate Engineering", "KEYCARD")
        SignatureValidator(signer_)
        Ownable()
    {
        migration = IERC721(migration_);
        metadataStore = metadataStore_;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return MetadataComposer.tokenURI(id, metadataKeys(id), imageKey(id), metadataStore);
    }

    function metadataKeys(uint256 id) public view returns (bytes32[] memory) {
        if (id <= OG_MAX) {
            return _constructKeys(id, OG_KEY);
        }
        return _constructKeys(id, ONBOARDING_KEY);
    }

    function imageKey(uint256 id) public view returns (bytes32) {
        bytes32 key = imageKeys[id];
        if (key == 0) {
            if (id <= OG_MAX) {
                return OG_KEY;
            } else {
                return ONBOARDING_KEY;
            }
        }
        return key;
    }

    function metadataNonce(uint256 id) public view returns (bytes32) {
        bytes32[] memory keys = metadataKeys(id);
        if (keys.length == 0) {
            return keccak256("NO_METADATA");
        }
        return keccak256(abi.encode(keys));
    }

    function applyMetadata(uint256 id, bytes32 metadataKey, bytes memory signature) public {
        if (msg.sender != ownerOf[id]) revert RequiresTokenOwner();
        _validateAttributeSignature(signature, msg.sender, metadataKey, id, metadataNonce(id));
        tokenMetadataKeys[id].push(metadataKey);
    }

    function applyImage(uint256 id, bytes32 imageKey_, bytes memory signature) public {
        if (msg.sender != ownerOf[id]) revert RequiresTokenOwner();
        _validateAttributeSignature(signature, msg.sender, imageKey_, id, imageKey(id));
        imageKeys[id] = imageKey_;
    }

    function mint(address to, uint256 id) public onlyOwner {
        if (id > MAX_SUPPLY || id < 1) revert InvalidTokenId();
        _safeMint(to, id);
    }

    function migrate(address to, uint256[] memory ids) public {
        if (msg.sender != address(migration)) revert InvalidMigrationCaller();
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (id > OG_MAX || id < 1) revert InvalidTokenId();
            if (ownerOf[id] != address(0)) revert TokenAlreadyMigrated();

            _safeMint(to, id);
        }
    }

    function ownerApplyImage(uint256 id, bytes32 imageKey_) public onlyOwner {
        if (ownerMetadataFunctionLocked) revert OwnerMetadataFunctionLocked();
        _validateToken(id);
        imageKeys[id] = imageKey_;
    }

    function ownerApplyMetadata(uint256 id, bytes32 metadataKey, bytes32 nonce) public onlyOwner {
        if (ownerMetadataFunctionLocked) revert OwnerMetadataFunctionLocked();
        _validateToken(id);

        if (metadataNonce(id) != nonce) revert IncorrectMetadataNonce();
        tokenMetadataKeys[id].push(metadataKey);
    }

    function _validateToken(uint256 id) private pure {
        if (id > MAX_SUPPLY || id < 1) revert InvalidTokenId();
    }

    function lockOwnerMetadataFunction() public onlyOwner {
        ownerMetadataFunctionLocked = true;
    }

    function _validateAttributeSignature(
        bytes memory signature,
        address owner,
        bytes32 key,
        uint256 tokenId,
        bytes32 nonce
    ) private view {
        bytes memory message = abi.encodePacked(owner, key, tokenId, nonce);
        _validateSignature(signature, message);
    }

    function _constructKeys(uint256 id, bytes32 addedKey) private view returns (bytes32[] memory) {
        bytes32[] memory keys = tokenMetadataKeys[id];
        bytes32[] memory constructed = new bytes32[](keys.length + 1);
        for (uint256 i = 0; i < keys.length; i++) {
            constructed[i] = keys[i];
        }
        constructed[keys.length] = addedKey;
        return constructed;
    }
}