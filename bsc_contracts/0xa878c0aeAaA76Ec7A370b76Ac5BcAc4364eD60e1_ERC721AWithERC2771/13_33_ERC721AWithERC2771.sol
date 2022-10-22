// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./base/ERC721ABaseERC2771.sol";
import "./extensions/supply/ERC721ASupplyExtension.sol";
import "./extensions/lockable/ERC721ALockableExtension.sol";
import "./extensions/mintable/ERC721AMintableExtension.sol";
import "./extensions/burnable/ERC721ABurnableExtension.sol";

/**
 * @title ERC721 (A) - with meta-transactions
 * @notice Azuki's implemntation of standard EIP-721 with ability to accept meta transactions (mainly transfer or burn methods).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:provides-interfaces IERC721 IERC721ABase IERC721SupplyExtension IERC721MintableExtension IERC721LockableExtension IERC721BurnableExtension
 */
contract ERC721AWithERC2771 is
    ERC721ABaseERC2771,
    ERC721ASupplyExtension,
    ERC721AMintableExtension,
    ERC721ABurnableExtension,
    ERC721ALockableExtension
{
    /**
     * @dev See {ERC721A-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721ABaseInternal, ERC721ALockableInternal, ERC721ASupplyExtension) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _msgSender() internal view virtual override(Context, ERC721ABaseERC2771) returns (address) {
        return ERC721ABaseERC2771._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC721ABaseERC2771) returns (bytes calldata) {
        return ERC721ABaseERC2771._msgData();
    }
}