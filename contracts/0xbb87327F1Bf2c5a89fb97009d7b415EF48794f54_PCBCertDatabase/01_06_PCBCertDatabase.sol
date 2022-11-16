// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC2981.sol";
import "./MerkleProofLib.sol";
import "./ERC1155.sol";

/// @notice Project Clear Book's Certification Database
/// @author Project Clear Book
contract PCBCertDatabase is Ownable, ERC1155 {
    string private ipfsHash;
    mapping(bytes32 => uint256) public merkleRootToId;
    mapping(uint256 => mapping(address => bool)) public didClaimMerkleDrop;

    constructor() {
        ipfsHash = "bafybeiaikcdp5oowxjw6mvalqoeylyqelctbcqi2ycbyu6wjhtkd6w3z7a";
    }

    function claimMerkleDrop(bytes32 root, bytes32[] calldata proof) external {
        uint256 id = merkleRootToId[root];
        require(id > 0);
        require(!didClaimMerkleDrop[id][msg.sender]);
        require(MerkleProofLib.verify(proof, root, keccak256(abi.encodePacked(msg.sender))));
        didClaimMerkleDrop[id][msg.sender] = true;
        _mint(msg.sender, id, 1, "");
    }

    function createMerkleDrop(bytes32 merkleRoot, uint256 id) external onlyOwner {
        require(merkleRootToId[merkleRoot] == 0);
        require(id > 0);
        merkleRootToId[merkleRoot] = id;
    }

    function pushAirdrop(uint256 id, address[] calldata recipients) external onlyOwner {
        require(id > 0);
        for (uint256 i; i < recipients.length; i++) {
            _mint(recipients[i], id, 1, "");
        }
    }

    function updateMetadata(string calldata newHash) external onlyOwner {
        ipfsHash = newHash;
    }

    function royaltyInfo(uint256, uint256 salePrice) public view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * 500) / 10000;
        return (owner(), royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat("ipfs://", ipfsHash, "/", _toHexString(id), ".json");
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function _toHexString(uint256 value) private pure returns (string memory) {
        bytes memory buffer = new bytes(64);
        for (uint256 i = 64; i > 0; --i) {
            buffer[i-1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}