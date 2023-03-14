// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "./libraries/AccessControlRecoverable.sol";
import "./libraries/OperatorAccess.sol";
import "./interfaces/IKompeteGameAsset.sol";
import "./interfaces/IProxyRegistry.sol";

contract KompeteGameAssetFactory is Context, AccessControl, OperatorAccess, AccessControlRecoverable {
    IKompeteGameAsset public immutable assetCollection;

    constructor(IKompeteGameAsset _assetCollection) {
        assetCollection = _assetCollection;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyOperatorsOrProxy() {
        if (!hasRole(OPERATOR_ROLE, _msgSender())) {
            address registry = assetCollection.registry();
            require(registry != address(0), "Factory: operator role or registry required");

            IProxyRegistry proxyRegistry = IProxyRegistry(registry);
            IAuthenticatedProxy proxy = IAuthenticatedProxy(_msgSender());
            require(exists(address(proxy)), "Factory: invalid proxy");

            address proxied = proxy.user();
            require(proxied != address(0), "Factory: invalid proxied address");

            address registered = address(proxyRegistry.proxies(proxied));
            require(_msgSender() == registered, "Factory: invalid proxy for user");

            require(hasRole(OPERATOR_ROLE, proxied), "Factory: operator role required for proxy");
        }
        _;
    }

    /**
     * @dev Mint tokens from the asset collection
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyOperatorsOrProxy {
        assetCollection.mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual onlyOperatorsOrProxy {
        assetCollection.mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Set the max supply for a tokenId
     */
    function setMaxSupply(
        uint256 id,
        uint256 max,
        bool freeze
    ) external onlyOperators {
        assetCollection.setMaxSupply(id, max, freeze);
    }

    function exists(address what) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    function canMint(address collection, address account) public view returns (bool) {
        return collection == address(assetCollection) && hasRole(OPERATOR_ROLE, account);
    }
}