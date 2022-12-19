// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ITierV2.sol";

abstract contract TierV2 is ITierV2, ERC165 {
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId_ == type(ITierV2).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}