// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ResolverBase.sol";
import "./interfaces/ITextResolver.sol";

abstract contract TextResolver is ITextResolver, ResolverBase {
    mapping(bytes32 => mapping(string => string)) texts;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external virtual authorized(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    function text(
        bytes32 node,
        string calldata key
    ) external view virtual override returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns (bool) {
        return
            interfaceID == type(ITextResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    uint256[49] private __gap;
}