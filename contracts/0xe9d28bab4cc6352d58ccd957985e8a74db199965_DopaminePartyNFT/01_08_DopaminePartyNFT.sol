pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {ERC1155NT} from "../erc1155/ERC1155NT.sol";
import {IDopaminePartyNFT} from "../interfaces/IDopaminePartyNFT.sol";

/// @title Dopamine Party NFTs
/// @notice Dopamine Party NFTs are non-transferable ERC-1155s given to
///  attendees of Dopamine's various IRL or virtual events & parties. This
///  ERC-1155 implementation additionally supports per NFT type supply tracking
///  and minting through airdrops or merkle allowlist claims. Each NFT type
///  uniquely identifies a specific party, thus attendees may own 1 max of each.
contract DopaminePartyNFT is ERC1155NT, IDopaminePartyNFT {

    string public name = "Dopamine Party NFTs";

    string public symbol = "PARTY";

    /// @notice The address administering NFT distributions and metadata.
    address public owner;

    /// @notice The URI each NFT initially points to for metadata resolution.
    /// @dev Before URI finalization, `uri()` resolves to "{baseURI}/{id}".
    string public baseURI;

    /// @notice Maps the id of an NFT type to its finalized metadata URI.
    /// @dev After URI finalization, `uri()` resolves to "{tokenURI[id]}".
    mapping(uint256 => string) public tokenURI;

    /// @notice Gets for a specific NFT type its total supply.
    mapping(uint256 => uint256) public totalSupply;

    // Merkle roots for each NFT type (null if NFT type is not claimable).
    mapping(uint256 => bytes32) private _allowlist;

    // Counter for tracking the current NFT type id.
    uint256 private _id;

    /// @dev Restricts a function call to address `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Initializes contract with given base URI and sender as owner.
    /// @param baseURI_ The base URI address involved in fetching NFT metadata.
    constructor(string memory baseURI_) {
        baseURI = baseURI_;
        emit BaseURISet(baseURI);

        owner = msg.sender;
        emit OwnerChanged(address(0), owner);
    }

    /// @inheritdoc IDopaminePartyNFT
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @inheritdoc IDopaminePartyNFT
    function setOwner(address newOwner) external onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    /// @inheritdoc IDopaminePartyNFT
    function setTokenURI(uint256 id, string calldata newTokenURI)
        external
        onlyOwner
    {
        if (id >= _id) {
            revert TokenNonExistent();
        }
        if (bytes(tokenURI[id]).length != 0) {
            revert TokenImmutable();
        }
        tokenURI[id] = newTokenURI;
        emit TokenURISet(id, newTokenURI);
    }

    /// @notice Returns the metadata URI for NFT type with id `id`.
    /// @param id The id of the type of NFT being queried.
    function uri(uint256 id) external view returns (string memory) {
        if (totalSupply[id] == 0) {
            revert TokenNonExistent();
        }

        if (bytes(tokenURI[id]).length == 0) {
            return string(abi.encodePacked(baseURI, _toString(id)));
        } else {
            return tokenURI[id];
        }
    }

    /// @inheritdoc IDopaminePartyNFT
    function allowlist(uint256 id, bytes32 allowlistRoot) external onlyOwner {
        if (id > _id) {
            revert TokenNonExistent();
        }

        // Retroactive claim changes are disallowed once metadata is immutable.
        if (bytes(tokenURI[id]).length != 0) {
            revert TokenImmutable();
        }

        _allowlist[id] = allowlistRoot;
        if (id == _id) {
            _id += 1;
            emit PartyNFTCreated(id, allowlistRoot);
        } else {
            emit PartyNFTUpdated(id, allowlistRoot);
        }
    }

    /// @inheritdoc IDopaminePartyNFT
    function airdrop(uint256 id, address[] calldata addresses)
        external
        onlyOwner
    {
        if (id > _id) {
            revert TokenNonExistent();
        }

        // Retroactive airdrops are disallowed once metadata is immutable.
        if (bytes(tokenURI[id]).length != 0) {
            revert TokenImmutable();
        }

        if (id == _id) {
            _id += 1;
            emit PartyNFTCreated(id, "");
        } else {
            emit PartyNFTUpdated(id, "");
        }

        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; i++) {
            _mint(addresses[i], id);
        }
        totalSupply[id] += numAddresses;
    }

    // @inheritdoc IDopaminePartyNFT
    function claim(bytes32[] calldata proof, uint256 id) external {
        bytes32 tokenAllowlist = _allowlist[id];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!_verify(tokenAllowlist, proof, leaf)) {
            revert ProofInvalid();
        }

        _mint(msg.sender, id);
        totalSupply[id]++;
    }

    /// @dev Checks whether `leaf` is part of merkle tree rooted at `merkleRoot`
    ///  using proof `proof`. Merkle tree generation and proof construction is
    ///  done using the following JS library: github.com/miguelmota/merkletreejs
    /// @param merkleRoot The hexlified merkle root as a bytes32 data type.
    /// @param proof The abi-encoded proof formatted as a bytes32 array.
    /// @param leaf The leaf node being checked (uses keccak-256 hashing).
    /// @return True if `leaf` is in `merkleRoot`-rooted tree, False otherwise.
    function _verify(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (hash <= proofElement) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }
        }
        return hash == merkleRoot;
    }

    /// @dev Converts a uint256 into a string.
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}