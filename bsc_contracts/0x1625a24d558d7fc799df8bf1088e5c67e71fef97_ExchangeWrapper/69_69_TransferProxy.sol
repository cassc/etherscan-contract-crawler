// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../operator/OperatorRole.sol";
import "../interfaces/INftTransferProxy.sol";

contract TransferProxy is INftTransferProxy, Initializable, OperatorRole {
    function __TransferProxy_init() external initializer {
        __Ownable_init();
    }

    function erc721safeTransferFrom(
        IERC721Upgradeable token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override onlyOperator {
        token.safeTransferFrom(from, to, id, value, data);
    }
}