// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

error SoulBoundContract(string message);

abstract contract SoulboundERC1155 is IERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    string constant REVERT_ERROR = "This Token is Soul bound. Only balance and metadata can be read";

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId;
    }

    function setApprovalForAll(address, bool) public virtual override {
        revert SoulBoundContract(REVERT_ERROR);
    }

    function isApprovedForAll(address, address) public pure virtual override returns (bool) {
        return false;
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure {
        revert SoulBoundContract(REVERT_ERROR);
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure {
        revert SoulBoundContract(REVERT_ERROR);
    }

    uint256[49] __gap;
}