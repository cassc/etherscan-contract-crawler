// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC165Controller } from "../../core/introspection/ERC165Controller.sol";
import { OwnableController } from "../../core/access/ownable/OwnableController.sol";
import { ERC721MintableController } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { ERC721TokenURIController } from "../../core/token/ERC721/tokenURI/ERC721TokenURIController.sol";
import { ERC721EnumerableController } from "../../core/token/ERC721/enumerable/ERC721EnumerableController.sol";
import { ERC721MintableController } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { PageInfo } from "../../core/token/ERC721/enumerable/ERC721EnumerableModel.sol";
import { ProxyFacetedController } from "../../core/proxy/faceted/ProxyFacetedController.sol";
import { IntegerUtils } from "../../core/utils/IntegerUtils.sol";

/**
 * @title Mutytes initialization facet
 */
contract MutytesInitFacet is
    ERC165Controller,
    OwnableController,
    ERC721MintableController,
    ERC721TokenURIController,
    ERC721EnumerableController,
    ProxyFacetedController
{
    using IntegerUtils for uint256;

    /**
     * @notice Set upgradable functions and supported interfaces
     * @param selectors The upgradable function selectors
     * @param isUpgradable Whether the functions should be upgradable
     * @param interfaceIds The interface ids
     * @param isSupported Whether the interfaces should be supported
     */
    function setFunctionsAndInterfaces(
        bytes4[] calldata selectors,
        bool isUpgradable,
        bytes4[] calldata interfaceIds,
        bool isSupported
    ) external virtual onlyOwner {
        setUpgradableFunctions_(selectors, isUpgradable);
        _setSupportedInterfaces(interfaceIds, isSupported);
    }

    /**
     * @notice Set upgradable functions
     * @param selectors The upgradable function selectors
     * @param isUpgradable Whether the functions should be upgradable
     */
    function setUpgradableFunctions(bytes4[] calldata selectors, bool isUpgradable)
        external
        virtual
        onlyOwner
    {
        setUpgradableFunctions_(selectors, isUpgradable);
    }

    /**
     * @notice Set supported interfaces
     * @param interfaceIds The interface ids
     * @param isSupported Whether the interfaces should be supported
     */
    function setSupportedInterfaces(bytes4[] calldata interfaceIds, bool isSupported)
        external
        virtual
        onlyOwner
    {
        _setSupportedInterfaces(interfaceIds, isSupported);
    }

    /**
     * @notice Initialize the default token URI provider
     * @param id The URI provider id
     * @param provider The URI provider address
     * @param isProxyable Whether to proxy the URI provider
     */
    function initTokenURI(
        uint256 id,
        address provider,
        bool isProxyable
    ) external virtual onlyOwner {
        ERC721TokenURI_(id, provider, isProxyable);
    }

    /**
     * @notice Initialize the token supply and mint reserved tokens
     * @param supply The initial supply amount
     * @param reserved The reserved supply amount
     */
    function initSupply(uint256 supply, uint256 reserved) external virtual onlyOwner {
        reserved.enforceNotGreaterThan(supply);
        ERC721Supply_(supply);

        if (reserved > 0) {
            (uint256 tokenId, uint256 maxTokenId) = _mint_(msg.sender, reserved);

            unchecked {
                while (tokenId < maxTokenId) {
                    emit Transfer(address(0), msg.sender, tokenId++);
                }
            }
        }
    }

    /**
     * @notice Initialize enumerable extension
     * @param pages The enumerable token pages
     */
    function initEnumerable(PageInfo[] calldata pages) external virtual onlyOwner {
        _ERC721Enumerable(pages);
    }

    /**
     * @notice Burn any remaining supply
     */
    function burnRemainingSupply() external virtual onlyOwner {
        uint256 availableSupply = _availableSupply();
        availableSupply.enforceIsNotZero();
        _setAvailableSupply(0);
        _updateMaxSupply(availableSupply);
        _updateInitialSupply(availableSupply);
    }
}