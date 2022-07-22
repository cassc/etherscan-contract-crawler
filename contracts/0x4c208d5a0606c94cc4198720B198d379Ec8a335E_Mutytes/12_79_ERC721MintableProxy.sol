// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Mintable } from "./IERC721Mintable.sol";
import { ERC721MintableController } from "./ERC721MintableController.sol";
import { ProxyUpgradableController } from "../../../proxy/upgradable/ProxyUpgradableController.sol";

/**
 * @title ERC721 token minting extension implementation
 * @dev Note: Upgradable implementation
 */
abstract contract ERC721MintableProxy is
    IERC721Mintable,
    ERC721MintableController,
    ProxyUpgradableController
{
    /**
     * @inheritdoc IERC721Mintable
     */
    function mint(uint256 amount) external payable virtual override upgradable {
        mint_(amount);
    }
}