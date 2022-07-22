// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMutytesToken } from "./IMutytesToken.sol";
import { MutytesTokenController } from "./MutytesTokenController.sol";
import { ERC165Proxy } from "../../core/introspection/ERC165Proxy.sol";
import { ERC721Proxy } from "../../core/token/ERC721/ERC721Proxy.sol";
import { ERC721MetadataProxy } from "../../core/token/ERC721/metadata/ERC721MetadataProxy.sol";
import { ERC721EnumerableProxy } from "../../core/token/ERC721/enumerable/ERC721EnumerableProxy.sol";
import { ERC721MintableProxy } from "../../core/token/ERC721/mintable/ERC721MintableProxy.sol";
import { ERC721MintableController, ERC721MintableModel } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { ERC721BurnableProxy, ERC721BurnableController } from "../../core/token/ERC721/burnable/ERC721BurnableProxy.sol";

/**
 * @title Mutytes token implementation
 * @dev Note: Upgradable implementation
 */
abstract contract MutytesTokenProxy is
    IMutytesToken,
    ERC165Proxy,
    ERC721Proxy,
    ERC721MetadataProxy,
    ERC721EnumerableProxy,
    ERC721MintableProxy,
    ERC721BurnableProxy,
    MutytesTokenController
{
    /**
     * @inheritdoc IMutytesToken
     */
    function availableSupply() external virtual upgradable returns (uint256) {
        return _availableSupply();
    }

    /**
     * @inheritdoc IMutytesToken
     */
    function mintBalanceOf(address owner) external virtual upgradable returns (uint256) {
        return mintBalanceOf_(owner);
    }

    function _burn_(address owner, uint256 tokenId)
        internal
        virtual
        override(ERC721BurnableController, MutytesTokenController)
    {
        super._burn_(owner, tokenId);
    }

    function _maxMintBalance()
        internal
        pure
        virtual
        override(ERC721MintableModel, MutytesTokenController)
        returns (uint256)
    {
        return super._maxMintBalance();
    }
}