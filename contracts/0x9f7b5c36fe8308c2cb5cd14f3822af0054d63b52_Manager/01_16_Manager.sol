// // contracts/MyContract.sol
// // SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Manager is AccessControlEnumerableUpgradeable {
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED");

    // Nonce
    mapping(uint256 => bool) private _usedNonces;

    function initialize() public initializer { 
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFromERC20(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) public virtual onlyRole(WHITELISTED_ROLE) returns (bool) {
        require(!_usedNonces[nonce], "Nonce already used");
        _usedNonces[nonce] = true;
        return token.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function safeTransferFromERC721(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 nonce
    ) public virtual onlyRole(WHITELISTED_ROLE) {
        require(!_usedNonces[nonce], "Nonce already used");
        _usedNonces[nonce] = true;
        return token.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Method to transfer batch of ERC721 tokens
     */
    function safeBatchTransferFromERC721(
        IERC721 token,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256 nonce
    ) public virtual onlyRole(WHITELISTED_ROLE) {
        require(!_usedNonces[nonce], "Nonce already used");
        _usedNonces[nonce] = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.safeTransferFrom(from, to, tokenIds[i]);
        }
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFromERC1155(
        IERC1155 token,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        uint256 nonce
    ) public virtual onlyRole(WHITELISTED_ROLE) {
        require(!_usedNonces[nonce], "Nonce already used");
        _usedNonces[nonce] = true;
       token.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFromERC1155(
        IERC1155 token,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        uint256 nonce
    ) public virtual onlyRole(WHITELISTED_ROLE) {
        require(!_usedNonces[nonce], "Nonce already used");
        _usedNonces[nonce] = true;
        token.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}