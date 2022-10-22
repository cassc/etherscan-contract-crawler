// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "../../extensions/mintable/IERC721MintableExtension.sol";
import "./IERC721MintableOwnable.sol";

/**
 * @title ERC721 - Mint as owner
 * @notice Allow minting as contract owner with no restrictions (supports ERC721A).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension
 * @custom:provides-interfaces IERC721MintableOwnable
 */
contract ERC721MintableOwnable is IERC721MintableOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC721MintableOwnable
     */
    function mintByOwner(address to, uint256 amount) public virtual onlyOwner {
        IERC721MintableExtension(address(this)).mintByFacet(to, amount);
    }

    /**
     * @inheritdoc IERC721MintableOwnable
     */
    function mintByOwner(address[] calldata tos, uint256[] calldata amounts) public virtual onlyOwner {
        IERC721MintableExtension(address(this)).mintByFacet(tos, amounts);
    }
}