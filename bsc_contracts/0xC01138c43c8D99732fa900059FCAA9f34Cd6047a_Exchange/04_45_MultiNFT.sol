// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../common/ERC2771ContextUpgradeable.sol";
import "../common/RoyaltyUpgradeable.sol";

contract MultiNFT is Initializable, ERC2771ContextUpgradeable, ERC1155Upgradeable, AccessControlUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable, RoyaltyUpgradeable, UUPSUpgradeable {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant EXCHANGE_ROLE = keccak256("EXCHANGE_ROLE");

    function initialize(address forwarder, address exchnage) initializer public {
        __ERC1155_init("");
        __RoyaltyUpgradeable_init();
        __AccessControl_init();
        __ERC1155URIStorage_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        __ERC2771ContextUpgradeable_init(forwarder);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(EXCHANGE_ROLE, exchnage);
    }

    // mint

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintWithUri(address account, uint256 id, uint256 amount, bytes memory data, string memory newuri)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);

        _setURI(id, newuri);
    }

    function mintAndApprove(address account, uint256 id, uint256 amount, bytes memory data, string memory newuri, address spender) 
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);

        _setURI(id, newuri);
        _setApprovalForAll(account, spender, true);
    }

    function mintAndSetRoyalty(address account, uint256 id, uint256 amount, bytes memory data, string memory newuri, address receiver, uint96 feeNumerator)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);

        _setURI(id, newuri);
        _setTokenRoyalty(id, receiver, feeNumerator);
    }

    function exchangeMint(address account, uint256 id, uint256 amount, string memory newuri, address receiver, uint96 feeNumerator, address exchange)
        public
        onlyRole(EXCHANGE_ROLE)
    {
        _mint(account, id, amount, "Mint by exchange");

        _setURI(id, newuri);
        _setApprovalForAll(account, exchange, true);
        _setTokenRoyalty(id, receiver, feeNumerator);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // uri
    function uri(uint256 tokenId) public view virtual override(ERC1155URIStorageUpgradeable, ERC1155Upgradeable) returns (string memory) {
        return super.uri(tokenId);
    }

    // Set royalty

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, RoyaltyUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}