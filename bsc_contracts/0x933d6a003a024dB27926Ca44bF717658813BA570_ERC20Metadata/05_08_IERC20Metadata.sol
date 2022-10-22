// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../common/metadata/IMetadata.sol";

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IMetadata {
    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}