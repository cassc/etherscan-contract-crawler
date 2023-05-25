// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ERC165Storage.sol";

/**
 * @title ERC165
 * @notice Standard EIP-165 facet which would be already included as a core facet in Flair's Diamond contract.
 *
 * @custom:type eip-2535-facet
 * @custom:category Introspection
 * @custom:provides-interfaces IERC165
 */
contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}