// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "./extensions/ERC1155CapSupply.sol";
import "./extensions/ERC1155Metadata.sol";
import "./libraries/PauserAccess.sol";
import "./interfaces/IMintableERC1155.sol";
import "./interfaces/IProxyRegistry.sol";

contract KompeteGameAsset is
    Context,
    AccessControl,
    PauserAccess,
    ERC1155Metadata,
    ERC1155CapSupply,
    ERC1155Burnable,
    ERC1155Pausable,
    IMintableERC1155
{
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    address public registry;
    string public contractURI;

    constructor(
        address _registry,
        string memory _uri,
        string memory _name
    ) ERC1155(_uri) ERC1155Metadata(_name) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        registry = _registry;
    }

    modifier onlyAdmins() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Game: admin role required");
        _;
    }

    modifier onlyFactory() {
        require(hasRole(FACTORY_ROLE, _msgSender()), "Game: factory role required");
        _;
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `FACTORY_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external override onlyFactory {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Batched variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external override onlyFactory {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Set the max supply for a tokenId
     */
    function setMaxSupply(
        uint256 id,
        uint256 max,
        bool freeze
    ) external onlyFactory {
        _setMaxSupply(id, max, freeze);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155CapSupply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        // Whitelist proxy contract for easy trading.
        if (registry != address(0)) {
            IProxyRegistry proxyRegistry = IProxyRegistry(registry);
            if (address(proxyRegistry.proxies(account)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(account, operator);
    }

    function setProxyRegistry(address _registry) external onlyAdmins {
        require(registry == address(0), "Game: registry already set");
        registry = _registry;
    }

    function setURI(string memory newuri) external onlyAdmins {
        require(bytes(newuri).length > 0, "Game: empty uri");
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) external onlyAdmins {
        require(bytes(newuri).length > 0, "Game: empty uri");
        contractURI = newuri;
    }
}