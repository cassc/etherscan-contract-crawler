// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "../../extensions/mintable/IERC1155MintableExtension.sol";
import "../../base/ERC1155BaseInternal.sol";
import "./IERC1155MintableOwnable.sol";

/**
 * @title ERC1155 - Mint as owner
 * @notice Allow minting as contract owner with no restrictions.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155MintableExtension
 * @custom:provides-interfaces IERC1155MintableOwnable
 */
contract ERC1155MintableOwnable is IERC1155MintableOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC1155MintableOwnable
     */
    function mintByOwner(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyOwner {
        IERC1155MintableExtension(address(this)).mintByFacet(to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155MintableOwnable
     */
    function mintByOwner(
        address[] calldata tos,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata datas
    ) public virtual onlyOwner {
        IERC1155MintableExtension(address(this)).mintByFacet(tos, ids, amounts, datas);
    }
}