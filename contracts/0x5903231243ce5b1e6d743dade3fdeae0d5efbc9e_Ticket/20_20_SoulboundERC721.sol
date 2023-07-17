// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

error SoulBoundContract(string message);

abstract contract SoulboundERC721 is ERC721Upgradeable {
    string constant REVERT_ERROR = "This Token is Soul bound.";

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override(ERC721Upgradeable) {
        revert SoulBoundContract(REVERT_ERROR);
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override(ERC721Upgradeable) {
        revert SoulBoundContract(REVERT_ERROR);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override(ERC721Upgradeable) {
        revert SoulBoundContract(REVERT_ERROR);
    }

    function approve(
        address,
        uint256
    ) public virtual override(ERC721Upgradeable) {
        revert SoulBoundContract(REVERT_ERROR);
    }

    function setApprovalForAll(
        address,
        bool
    ) public virtual override(ERC721Upgradeable) {
        revert SoulBoundContract(REVERT_ERROR);
    }

    uint256[49] __gap;
}