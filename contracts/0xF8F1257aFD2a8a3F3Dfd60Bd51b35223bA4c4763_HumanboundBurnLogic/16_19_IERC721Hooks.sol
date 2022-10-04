//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

interface IERC721Hooks {
    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

abstract contract ERC721HooksExtension is IERC721Hooks, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function _beforeTokenTransfer(address from, address to, uint256 tokenId) external;\n"
            "function _afterTokenTransfer(address from, address to, uint256 tokenId) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](2);
        functions[0] = IERC721Hooks._beforeTokenTransfer.selector;
        functions[1] = IERC721Hooks._afterTokenTransfer.selector;

        interfaces[0] = Interface(type(IERC721Hooks).interfaceId, functions);
    }
}