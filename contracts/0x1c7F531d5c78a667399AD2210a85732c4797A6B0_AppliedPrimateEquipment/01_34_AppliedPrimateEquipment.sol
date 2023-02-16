// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./lib/FragmentERC721Upgradeable.sol";

contract AppliedPrimateEquipment is FragmentERC721Upgradeable {
    function initialize(string memory name_, string memory symbol_, address owner_) public initializer {
        __FragmentERC721_init(name_, symbol_, owner_);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function operatorMint(address to, uint256 tokenId) public onlyOperator {
        _safeMint(to, tokenId);
    }
}