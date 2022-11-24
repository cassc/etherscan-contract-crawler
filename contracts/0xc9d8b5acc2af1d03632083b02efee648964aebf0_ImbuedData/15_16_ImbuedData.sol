// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

import "./deployed/IImbuedNFT.sol";

contract ImbuedData is AccessControlUpgradeable {
    IImbuedNFT public constant NFT = IImbuedNFT(0x000001E1b2b5f9825f4d50bD4906aff2F298af4e);
    bytes32 public constant IMBUER_ROLE = keccak256("IMBUER_ROLE");

    event Imbued(uint256 indexed tokenId, address indexed owner, string imbuement);

    struct Imbuement {
        bytes32 imbuement;
        address imbuer;
        uint96 timestamp;
    }

    mapping (uint256 => Imbuement[]) public imbuements;
    mapping (uint256 => bytes32) public tokenEntropy;

    constructor() initializer {}

    function initialize(address[] calldata imbuers, address admin) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(IMBUER_ROLE, admin);
        unchecked {
            for (uint256 i = 0; i < imbuers.length; ++i) {
                _grantRole(IMBUER_ROLE, imbuers[i]);
            }
        }
    }

    function imbue(uint256 tokenId, bytes32 imbuement) external {
        require(NFT.ownerOf(tokenId) == msg.sender, "Caller is not owner");
        _imbue(tokenId, imbuement, msg.sender, uint96(block.timestamp));
    }

    function imbueAdmin(uint256 tokenId, bytes32 imbuement, address imbueFor, uint96 timestamp) external {
        require(hasRole(IMBUER_ROLE, msg.sender), "Caller is not an imbuer");
        _imbue(tokenId, imbuement, imbueFor, timestamp);
    }

    function imbueAdmin(
            uint256[] calldata tokenId,
            bytes32[] calldata imbuement,
            address[] calldata imbueFor,
            uint96[] calldata timestamp)
        external {
        require(hasRole(IMBUER_ROLE, msg.sender), "Caller is not an imbuer");
        require(tokenId.length == imbuement.length, "Arrays must be same length");
        require(tokenId.length == imbueFor.length, "Arrays must be same length");
        require(tokenId.length == timestamp.length, "Arrays must be same length");
        for (uint256 i = 0; i < tokenId.length; ++i) {
            _imbue(tokenId[i], imbuement[i], imbueFor[i], timestamp[i]);
        }
    }

    function _imbue(uint256 tokenId, bytes32 imbuement, address imbuer, uint96 timestamp) internal {
        require(uint(imbuement) != 0, "Imbuement cannot be empty");
        Imbuement memory imb = Imbuement(imbuement, imbuer, timestamp);
        imbuements[tokenId].push(imb);

        bytes32 oldEntropy = tokenEntropy[tokenId];
        bytes32 newEntropy = keccak256(abi.encodePacked(oldEntropy, imbuement));
        tokenEntropy[tokenId] = newEntropy;

        bytes memory imb_bytes = abi.encodePacked(imbuement);
        emit Imbued(tokenId, imbuer, string(imb_bytes));
    }

    // View functions.

    function getNumImbuements(uint256 tokenId) external view returns (uint256) {
        return imbuements[tokenId].length;
    }

    function getLastImbuement(uint256 tokenId) external view returns (Imbuement memory) {
        Imbuement[] memory imb = imbuements[tokenId];
        require(imb.length > 0, "No imbuements");
        return imb[imb.length - 1];
    }

    function getEntropy(uint8 edition) external view returns (bytes memory) {
        require(edition < 7, "Invalid edition");
        bytes memory entropy = new bytes(0);
        uint start = uint(edition) * 100;
        unchecked {
            for (uint i ; i < 100; ++i) {
                bytes2 prefix = bytes2(tokenEntropy[start + i]);
                entropy = bytes.concat(entropy, prefix);
            }
        }
        return entropy;
    }
}