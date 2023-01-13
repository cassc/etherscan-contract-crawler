// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

import "../SBT.sol";

/**
 * @title SBT Burnable Token
 * @dev SBT Token that can be burned (destroyed).
 */
abstract contract SBTBurnable is Context, SBT {
    /**
     * @dev Burns `tokenId`. See {SBT-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isOwner(_msgSender(), tokenId),
            "SBT: caller is not token owner"
        );
        _burn(tokenId);
    }
}