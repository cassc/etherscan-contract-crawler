// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import {IWrapperValidator} from "./interfaces/IWrapperValidator.sol";

import {ERC721Wrapper} from "./ERC721Wrapper.sol";

contract KodaWrapper is ERC721Wrapper {
    function initialize(
        IERC721MetadataUpgradeable underlyingToken_,
        IWrapperValidator validator_,
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC721Wrapper_init(underlyingToken_, validator_, name, symbol);
    }
}