// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {IERC1155Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import {ERC1155BurnableUpgradeable} from
    "openzeppelin-contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {IERC1155MetadataURIUpgradeable} from
    "openzeppelin-contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import {IERC2981Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from
    "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import {IEmint1155} from "../interfaces/IEmint1155.sol";
import {ITokens} from "../interfaces/ITokens.sol";
import {IMetadata} from "../interfaces/IMetadata.sol";
import {IRoyalties} from "../interfaces/IRoyalties.sol";

contract Emint1155 is IEmint1155, ERC1155BurnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    string public constant NAME = "Emint1155";
    string public constant VERSION = "0.0.1";

    address public tokens;

    modifier onlyTokens() {
        if (msg.sender != tokens) {
            revert Forbidden();
        }
        _;
    }

    constructor() {
        // Prevent initialization of the implementation contract.
        _disableInitializers();
    }

    /// @inheritdoc IEmint1155
    function initialize(address _tokens) external override initializer {
        __ERC1155_init("");
        __DefaultOperatorFilterer_init();
        tokens = _tokens;
    }

    /// @inheritdoc IEmint1155
    function metadata() public view override returns (address) {
        return ITokens(tokens).metadata();
    }

    /// @inheritdoc IEmint1155
    function royalties() public view override returns (address) {
        return ITokens(tokens).royalties();
    }

    /// @inheritdoc IEmint1155
    function owner() public view override returns (address) {
        return IMetadata(metadata()).owner(address(this));
    }

    /// @inheritdoc IEmint1155
    function contractURI() public view override returns (string memory) {
        return IMetadata(metadata()).contractURI(address(this));
    }

    /// @inheritdoc IERC1155MetadataURIUpgradeable
    function uri(uint256 tokenId)
        public
        view
        override (ERC1155Upgradeable, IERC1155MetadataURIUpgradeable)
        returns (string memory)
    {
        return IMetadata(metadata()).uri(tokenId);
    }

    /// @inheritdoc IERC2981Upgradeable
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address, uint256) {
        return IRoyalties(royalties()).royaltyInfo(tokenId, salePrice);
    }

    /// @inheritdoc IEmint1155
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external override onlyTokens {
        _mint(to, id, amount, data);
    }

    /// @inheritdoc IEmint1155
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        external
        override
        onlyTokens
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value)
        public
        override (ERC1155BurnableUpgradeable, IEmint1155)
    {
        super.burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values)
        public
        override (ERC1155BurnableUpgradeable, IEmint1155)
    {
        super.burnBatch(account, ids, values);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC1155Upgradeable, IERC1155Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override (ERC1155Upgradeable, IERC1155Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override (ERC1155Upgradeable, IERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC1155Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
}