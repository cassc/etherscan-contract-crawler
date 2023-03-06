// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC165Upgradeable, ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC1155BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {ERC1155SupplyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ILDPCLionade} from "./interfaces/ILDPCLionade.sol";

/**
 * @title LDPC Lionade
 * @custom:website https://lionsdenpoker.io/
 * @author https://twitter.com/lionsdenpoker
 * @notice The Lions Den Poker Club is more than just an NFT project – it’s a community of like-minded individuals who share a passion for poker and the opportunities that the blockchain provides.
 */
contract LDPCLionade is
    Initializable,
    AccessControlUpgradeable,
    ILDPCLionade,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    using Strings for uint256;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EXTERNAL_CONTRACT_ROLE =
        keccak256("EXTERNAL_CONTRACT_ROLE");

    function initialize() public initializer {
        __ERC1155_init(
            "ipfs://bafybeiervgkahad37niux7whxow4gd2unog7xmrpwxmpbjdcu7siazxy7a/"
        );
        __AccessControl_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    function name() external pure returns (string memory) {
        return "LDPC Lionade";
    }

    function symbol() external pure returns (string memory) {
        return "LDPCLA";
    }

    function setURI(string memory newuri) public onlyRole(OWNER_ROLE) {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @notice Mints tokens to a particular address
     * @param itemIds of mints
     */
    function airdrop(
        address _toAddress,
        uint256[] calldata itemIds
    ) external onlyRole(MINTER_ROLE) {
        uint256 amount = itemIds.length;
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            ids[i] = itemIds[i];
            amounts[i] = 1;
        }
        _mintBatch(_toAddress, ids, amounts, "");
    }

    /// @dev Allows an external contract w/ role to burn an item
    function burnItemForOwnerAddress(
        address _itemOwnerAddress,
        uint256 _typeId,
        uint256 _quantity
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _burn(_itemOwnerAddress, _typeId, _quantity);
    }

    /// @dev Allows an external contract w/ role to mint an item
    function mintItemToAddress(
        address _toAddress,
        uint256 _typeId,
        uint256 _quantity
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _mint(_toAddress, _typeId, _quantity, "");
    }

    /// @dev Allows an external contract w/ role to mint a batch of items to the same address
    function mintBatchItemsToAddress(
        address _toAddress,
        uint256[] memory _typeIds,
        uint256[] memory _quantities
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _mintBatch(_toAddress, _typeIds, _quantities, "");
    }

    /// @dev Allows a bulk transfer
    function bulkSafeTransfer(
        address[] calldata recipients,
        uint256 _typeId,
        uint256 _quantityPerRecipient
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransferFrom(
                _msgSender(),
                recipients[i],
                _typeId,
                _quantityPerRecipient,
                ""
            );
        }
    }

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

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            IERC165Upgradeable,
            ERC1155Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}