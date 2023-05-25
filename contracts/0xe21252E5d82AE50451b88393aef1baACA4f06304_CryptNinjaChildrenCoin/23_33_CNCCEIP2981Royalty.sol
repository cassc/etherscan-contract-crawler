// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AdminWithMinterBurnerControl.sol";
import '@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol';

contract CNCCEIP2981Royalty is EIP2981RoyaltyOverrideCore, AdminWithMinterBurnerControl {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, EIP2981RoyaltyOverrideCore)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }

    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyAdmin {
        _setTokenRoyalties(royaltyConfigs);
    }

    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyAdmin {
        _setDefaultRoyalty(royalty);
    }
}