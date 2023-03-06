// SPDX-License-Identifier: MIT
// Author: Philipp Adrian (ph101pp.eth)

pragma solidity ^0.8.0;

import "./ERC1155MintRange.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Extension of ERC1155MintRange enables ability to pause contract.
abstract contract ERC1155MintRangePausable is ERC1155MintRange, Pausable {
    
    function _setInitialHolders(address[] memory addresses)
        internal
        virtual
        override
        whenNotPaused
    {
        super._setInitialHolders(addresses);
    }

    function _mintRange(
        MintRangeInput memory input,
        bytes32 inputChecksum
    ) internal virtual override whenNotPaused {
        super._mintRange(input, inputChecksum);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}