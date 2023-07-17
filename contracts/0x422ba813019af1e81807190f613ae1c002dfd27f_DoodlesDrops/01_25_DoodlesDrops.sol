// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

/**
 * @title DoodlesDrops
 */
contract DoodlesDrops is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant METADATA_ROLE = keccak256("METADATA_ROLE");
    bytes32 public constant ROYALTY_ROLE = keccak256("ROYALTY_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    mapping(uint256 => bytes32) private _airdropMerkleRoots;
    mapping(uint256 => string) private _airdropMerkleIpfsHashes;
    mapping(uint256 => bool) private _airdropClaimEnabled;
    mapping(uint256 => mapping(address => bool)) private _airdropClaimed;

    mapping(uint256 => string) private _ipfsHashes;
    CountersUpgradeable.Counter private _idsCount;

    event Burn(address indexed operator, address indexed from, uint256[] ids, uint256[] amounts, bytes data);
    event Claim(address indexed account, uint256 indexed id, uint256 amount, bytes data);
    event MetadataSet(uint256 indexed id, string ipfsHash);

    error IdsArrayIsEmpty();
    error ReceiversArrayIsEmpty();
    error InvalidId();
    error NotTokenOwnerOrApproved();
    error InvalidProof();
    error ClaimIsNotEnabled();
    error AlreadyClaimed();

    modifier validDropId(uint256 id) {
        if (id >= _idsCount.current()) {
            revert InvalidId();
        }
        _;
    }

    modifier validDropIds(uint256[] calldata ids) {
        if (ids.length == 0) {
            revert IdsArrayIsEmpty();
        }

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (id >= _idsCount.current()) {
                revert InvalidId();
            }
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __ERC1155_init("");
        __ERC1155Supply_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(METADATA_ROLE, msg.sender);
        _grantRole(ROYALTY_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    receive() external payable {}

    /**
     * @dev Burn drops.
     *
     * @param from The address of the token owner.
     * @param id The id of the drop.
     * @param amount The amount of drops to burn.
     * @param data Additional data.
     */
    function burn(address from, uint256 id, uint256 amount, bytes memory data) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }

        _burn(from, id, amount);

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        emit Burn(msg.sender, from, ids, amounts, data);
    }

    /**
     * @dev Batch burn drops.
     *
     * @param from The address of the token owner.
     * @param ids The ids of the drops.
     * @param amounts The amounts of drops to burn.
     * @param data Additional data.
     */
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external {
        if (ids.length == 0) {
            revert IdsArrayIsEmpty();
        }
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }

        _burnBatch(from, ids, amounts);

        emit Burn(msg.sender, from, ids, amounts, data);
    }

    /**
     * @dev Claim airdrop. Claimer must provide a valid merkle proof.
     *
     * @param id The id of the drop.
     * @param amount The amount of drops to claim.
     * @param merkleProof The merkle proof.
     * @param data Additional data.
     */
    function claim(
        uint256 id,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bytes calldata data
    ) external validDropId(id) {
        if (!_airdropClaimEnabled[id]) {
            revert ClaimIsNotEnabled();
        }
        if (_airdropClaimed[id][msg.sender]) {
            revert AlreadyClaimed();
        }
        if (!_checkMerkleProof(id, msg.sender, amount, merkleProof)) {
            revert InvalidProof();
        }

        _airdropClaimed[id][msg.sender] = true;

        _mint(msg.sender, id, amount, data);

        emit Claim(msg.sender, id, amount, data);
    }

    /**
     * @dev Set drop metadata and royalties.
     *
     * @param id The id of the drop.
     * @param ipfsHash The IPFS hash of the drop metadata.
     * @param receiver The address of the royalty receiver.
     * @param feeNumerator The royalty fee numerator. Must be a value between 0 and 10000.
     */
    function setMetadataWithRoyalties(
        uint256 id,
        string calldata ipfsHash,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(METADATA_ROLE) onlyRole(ROYALTY_ROLE) {
        _setMetadata(id, ipfsHash);
        _setTokenRoyalty(id, receiver, feeNumerator);
    }

    /**
     * @dev Set drop metadata.
     *
     * @param id The id of the drop.
     * @param ipfsHash The IPFS hash of the drop metadata.
     */
    function setMetadata(uint256 id, string calldata ipfsHash) external onlyRole(METADATA_ROLE) {
        _setMetadata(id, ipfsHash);
    }

    /**
     * @dev Mint drops.
     *
     * @param to The address of the token receiver.
     * @param id The id of the drop.
     * @param amount The amount of drops to mint.
     * @param data Additional data.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) validDropId(id) {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Batch mint drops.
     *
     * @param to The address of the token receiver.
     * @param ids The ids of the drops.
     * @param amounts The amounts of drops to mint.
     * @param data Additional data.
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) validDropIds(ids) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Airdrop.
     *
     * @param to The addresses of the token receivers.
     * @param id The id of the drop.
     * @param amount The amount of drops to airdrop.
     * @param data Additional data.
     */
    function airdrop(
        address[] calldata to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) validDropId(id) {
        uint256 i = to.length;

        if (i == 0) {
            revert ReceiversArrayIsEmpty();
        }

        address receiver;

        unchecked {
            for (; i > 0; i--) {
                receiver = to[i - 1];
                _mint(receiver, id, amount, data);
            }
        }
    }

    /**
     * @dev Set the airdrop merkle root and IPFS hash of the merkle tree for a drop id.
     *
     * @param id The id of the drop.
     * @param _airdropMerkleRoot The merkle root.
     * @param _airdropMerkleIpfsHash The IPFS hash of the merkle tree.
     */
    function setAirdropMerkle(
        uint256 id,
        bytes32 _airdropMerkleRoot,
        string memory _airdropMerkleIpfsHash
    ) external onlyRole(AIRDROP_ROLE) validDropId(id) {
        _airdropMerkleRoots[id] = _airdropMerkleRoot;
        _airdropMerkleIpfsHashes[id] = _airdropMerkleIpfsHash;
    }

    /**
     * @dev Set the airdrop claim enabled flag for a drop id.
     *
     * @param id The id of the drop.
     * @param enabled The enabled flag.
     */
    function setAirdropClaimEnabled(uint256 id, bool enabled) external onlyRole(AIRDROP_ROLE) validDropId(id) {
        _airdropClaimEnabled[id] = enabled;
    }

    /**
     * @dev Set the default value for drop royalties.
     *
     * @param receiver The address of the royalty receiver.
     * @param feeNumerator The royalty fee numerator. Must be a value between 0 and 10000.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(ROYALTY_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Delete the default value for drop royalties.
     */
    function deleteDefaultRoyalty() external onlyRole(ROYALTY_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Set the royalty for a drop id. This will override the default royalty for that id.
     *
     * @param id The id of the drop.
     * @param receiver The address of the royalty receiver.
     * @param feeNumerator The royalty fee numerator. Must be a value between 0 and 10000.
     */
    function setTokenRoyalty(
        uint256 id,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(ROYALTY_ROLE) validDropId(id) {
        _setTokenRoyalty(id, receiver, feeNumerator);
    }

    /**
     * @dev Reset the royalty for a drop id. The default royalty will be used.
     *
     * @param id The id of the drop.
     */
    function resetTokenRoyalty(uint256 id) external onlyRole(ROYALTY_ROLE) validDropId(id) {
        _resetTokenRoyalty(id);
    }

    /**
     * @dev Withdraw the contract balance.
     */
    function withdraw() external onlyRole(WITHDRAWER_ROLE) {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev Get the count of drop ids.
     *
     * @return The count of drop ids.
     */
    function idsCount() external view returns (uint256) {
        return _idsCount.current();
    }

    /**
     * @dev Get the airdrop merkle root for a drop id.
     *
     * @param id The id of the drop.
     *
     * @return The airdrop merkle root.
     */
    function airdropMerkleRoot(uint256 id) external view returns (bytes32) {
        return _airdropMerkleRoots[id];
    }

    /**
     * @dev Get the airdrop merkle IPFS hash for a drop id.
     *
     * @param id The id of the drop.
     *
     * @return The airdrop merkle IPFS hash.
     */
    function airdropMerkleIpfsHash(uint256 id) external view returns (string memory) {
        return _airdropMerkleIpfsHashes[id];
    }

    /**
     * @dev Check if an airdrop claim is enabled for a drop id.
     *
     * @param id The id of the drop.
     *
     * @return The airdrop claim enabled flag.
     */
    function isAirdropClaimEnabled(uint256 id) external view returns (bool) {
        return _airdropClaimEnabled[id];
    }

    /**
     * @dev Check if an airdrop is claimed for a drop id and address.
     *
     * @param id The id of the drop.
     * @param addr The address of the claimer.
     *
     * @return The airdrop claimed flag.
     */
    function isAirdropClaimed(uint256 id, address addr) external view returns (bool) {
        return _airdropClaimed[id][addr];
    }

    /**
     * @dev Check if a merkle proof is valid for a drop id, address and amount.
     *
     * @param id The id of the drop.
     * @param addr The address of the claimer.
     * @param amount The amount of tokens to claim.
     *
     * @return The merkle proof valid flag.
     */
    function checkMerkleProof(
        uint256 id,
        address addr,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view validDropId(id) returns (bool) {
        return _checkMerkleProof(id, addr, amount, merkleProof);
    }

    /**
     * @dev Return the name of the contract.
     */
    function name() external pure returns (string memory) {
        return "Doodles Drops";
    }

    /**
     * @dev Return the symbol of the contract.
     */
    function symbol() external pure returns (string memory) {
        return "DOODLEDROP";
    }

    /**
     * @dev Return the drop uri.
     * This implementation does not rely on the token type id substitution mechanism.
     *
     * @param id The id of the drop.
     *
     * @return The drop uri.
     */
    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://", _ipfsHashes[id]));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal set metadata for a drop id.
     *
     * @param id The id of the drop.
     * @param ipfsHash The IPFS hash of the metadata.
     */
    function _setMetadata(uint256 id, string calldata ipfsHash) internal {
        if (id > _idsCount.current()) {
            revert InvalidId();
        }

        if (id == _idsCount.current()) {
            _idsCount.increment();
        }

        _ipfsHashes[id] = ipfsHash;

        emit MetadataSet(id, ipfsHash);
    }

    /**
     * @dev See {ERC1155Upgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Internal function to authorize an upgrade to the contract.
     *
     * @param newImplementation The address of the new implementation.
     * */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Internal check if a merkle proof is valid for a drop id, address and amount.
     *
     * @param id The id of the drop.
     * @param addr The address of the claimer.
     * @param amount The amount of tokens to claim.
     *
     * @return The merkle proof valid flag.
     */
    function _checkMerkleProof(
        uint256 id,
        address addr,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));
        return MerkleProofUpgradeable.verify(merkleProof, _airdropMerkleRoots[id], leaf);
    }
}