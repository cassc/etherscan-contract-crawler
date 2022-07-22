// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "erc721a/contracts/ERC721A.sol";

import "./ERC721AMinterExtension.sol";

import {IERC721PreSaleExtension} from "../../ERC721/extensions/ERC721PreSaleExtension.sol";

/**
 * @dev Extension to provide pre-sale capabilities for certain collectors to mint for a specific price.
 */
abstract contract ERC721APreSaleExtension is
    IERC721PreSaleExtension,
    Initializable,
    ERC165Storage,
    ERC721AMinterExtension,
    ReentrancyGuard
{
    uint256 public preSalePrice;
    uint256 public preSaleMaxMintPerWallet;
    bytes32 public preSaleAllowlistMerkleRoot;
    bool public preSaleStatus;

    mapping(address => uint256) internal preSaleAllowlistClaimed;

    function __ERC721APreSaleExtension_init(
        uint256 _preSalePrice,
        uint256 _preSaleMaxMintPerWallet
    ) internal onlyInitializing {
        __ERC721APreSaleExtension_init_unchained(
            _preSalePrice,
            _preSaleMaxMintPerWallet
        );
    }

    function __ERC721APreSaleExtension_init_unchained(
        uint256 _preSalePrice,
        uint256 _preSaleMaxMintPerWallet
    ) internal onlyInitializing {
        _registerInterface(type(IERC721PreSaleExtension).interfaceId);

        preSalePrice = _preSalePrice;
        preSaleMaxMintPerWallet = _preSaleMaxMintPerWallet;
    }

    /* ADMIN */

    function setPreSalePrice(uint256 newValue) external onlyOwner {
        preSalePrice = newValue;
    }

    function setPreSaleMaxMintPerWallet(uint256 newValue) external onlyOwner {
        preSaleMaxMintPerWallet = newValue;
    }

    function setAllowlistMerkleRoot(bytes32 newRoot) external onlyOwner {
        preSaleAllowlistMerkleRoot = newRoot;
    }

    function togglePreSaleStatus(bool isActive) external onlyOwner {
        preSaleStatus = isActive;
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721AMinterExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function onPreSaleAllowList(address minter, bytes32[] calldata proof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                preSaleAllowlistMerkleRoot,
                _generateMerkleLeaf(minter)
            );
    }

    function mintPreSale(uint256 count, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        require(preSaleStatus, "PRE_SALE_NOT_ACTIVE");

        address to = _msgSender();

        require(
            MerkleProof.verify(
                proof,
                preSaleAllowlistMerkleRoot,
                _generateMerkleLeaf(to)
            ),
            "PRE_SALE_WRONG_PROOF"
        );
        require(
            preSaleAllowlistClaimed[to] + count <= preSaleMaxMintPerWallet,
            "PRE_SALE_LIMIT"
        );
        require(preSalePrice * count <= msg.value, "INSUFFICIENT_AMOUNT");

        preSaleAllowlistClaimed[to] += count;

        _mintTo(to, count);
    }

    /* INTERNAL */

    function _generateMerkleLeaf(address account)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }
}